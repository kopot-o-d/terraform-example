# terraform {
#   backend "remote" {
#     organization = "BinaryStudio"
#     workspaces {
#       name = "terraform-example"
#     }
#   }
# }

provider "aws" {
  //profile = "default"
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

/// Instance role
///
///
///

resource "aws_iam_role" "ecs-instance-role" {
  name               = "ecs-instance-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-instance-policy.json
}

data "aws_iam_policy_document" "ecs-instance-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecs-instance-role-attachment" {
  role       = aws_iam_role.ecs-instance-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs-instance-profile" {
  name = "ecs-instance-profile"
  role = aws_iam_role.ecs-instance-role.id
}

///
///
///

/// Task role
///
///
///

resource "aws_iam_role" "ecs-task-role" {
  name               = "ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs-task-policy.json
}

resource "aws_iam_role_policy_attachment" "ecs-task-role-attachment" {
  role       = aws_iam_role.ecs-task-role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

data "aws_iam_policy_document" "ecs-task-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

///
///
///

/// Application Load Balancer
///
///
///
resource "aws_alb" "ecs-load-balancer" {
  name    = "ecs-load-balancer"
  subnets = ["subnet-998c83ff", "subnet-4b293703", "subnet-ea4109b0"]
}

resource "aws_alb_target_group" "ecs-target-group" {
  name     = "ecs-target-group"
  port     = "80"
  protocol = "HTTP"
  vpc_id   = "vpc-ac8e53d5"

  health_check {
    healthy_threshold   = "5"
    unhealthy_threshold = "2"
    interval            = "30"
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = "5"
  }
}

resource "aws_alb_listener" "alb-listener" {
  load_balancer_arn = aws_alb.ecs-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.ecs-target-group.arn
    type             = "forward"
  }
}
///
///
///

/// Launch Configuration
///
///
///
resource "aws_launch_configuration" "ecs-launch-configuration" {
  name_prefix          = "ecs-launch-configuration"
  image_id             = "ami-08803b8f0bf9db0ab"
  instance_type        = "t2.micro"
  iam_instance_profile = aws_iam_instance_profile.ecs-instance-profile.id

  root_block_device {
    volume_type           = "gp2"
    volume_size           = 30
    delete_on_termination = true
  }

  lifecycle {
    create_before_destroy = true
  }

  associate_public_ip_address = "true"
  key_name                    = "example-keypair"
  user_data                   = <<EOF
                                  #!/bin/bash
                                  echo ECS_CLUSTER=${aws_ecs_cluster.example-cluster.name} >> /etc/ecs/ecs.config;
                                  echo ECS_BACKEND_HOST= >> /etc/ecs/ecs.config;
                                  EOF
}
///
///
///

/// Auto Scaling Group
///
///
///
resource "aws_autoscaling_group" "ecs-autoscaling-group" {
  name                      = "ecs-autoscaling-group"
  max_size                  = 1
  min_size                  = 1
  desired_capacity          = 1
  launch_configuration      = aws_launch_configuration.ecs-launch-configuration.name
  health_check_type         = "EC2"
  health_check_grace_period = 300
  vpc_zone_identifier       = ["subnet-998c83ff", "subnet-4b293703", "subnet-ea4109b0"]
}
///
///
///

/// DB
///
///
///

# resource "aws_db_instance" "example" {
#   allocated_storage            = 20
#   max_allocated_storage        = 0
#   publicly_accessible          = true
#   apply_immediately            = true
#   skip_final_snapshot          = true
#   storage_type                 = "gp2"
#   engine                       = "postgres"
#   engine_version               = "12.4"
#   instance_class               = "db.t2.micro"
#   name                         = "database_example"
#   username                     = "postgres"
#   password                     = "admin"
#   parameter_group_name         = "default.postgres12"
#   backup_retention_period      = 0
#   auto_minor_version_upgrade   = true  // default
#   performance_insights_enabled = false // default
#   port                         = 5432  // default
#   monitoring_interval          = 0     // default
# }

///
///
///


/// ECS
///
///
///

resource "aws_ecs_cluster" "example-cluster" {
  name = "ecs-cluster"
}

data "template_file" "task_definition_template" {
  template = file("${path.module}/task-definition.json.tpl")
}

resource "aws_ecs_task_definition" "task_definition" {
  family                   = "worker"
  requires_compatibilities = ["EC2"]
  container_definitions    = data.template_file.task_definition_template.rendered
  task_role_arn            = aws_iam_role.ecs-task-role.arn
  execution_role_arn       = aws_iam_role.ecs-task-role.arn
}

resource "aws_ecs_service" "worker" {
  name                = "worker"
  cluster             = aws_ecs_cluster.example-cluster.id
  task_definition     = aws_ecs_task_definition.task_definition.arn
  desired_count       = 1
  scheduling_strategy = "REPLICA"
  launch_type         = "EC2"
  // wait_for_steady_state = true

  load_balancer {
    target_group_arn = aws_alb_target_group.ecs-target-group.arn
    container_name   = "client"
    container_port   = 80
  }
}

///
///
///

output "postgresql_endpoint" {
  value = aws_db_instance.example.endpoint
}

output "alb_endpoint" {
  value = aws_alb.ecs-load-balancer.dns_name
}

# output "ecr_repository_worker_endpoint" {
#   value = aws_ecr_repository.worker.repository_url
# }
