terraform {
  backend "remote" {
    organization = "BinaryStudio"
    workspaces {
      name = "terraform-example"
    }
  }
}

provider "aws" {
  //profile = "default"
  region     = var.region
  access_key = var.access_key
  secret_key = var.secret_key
}

resource "aws_instance" "example" {
  ami           = var.amis[var.region]
  instance_type = var.instance_type
}

output "ip" {
  value = aws_instance.example.private_ip
}

// terraform apply -var 'amis={ us-east-1 = "foo", us-west-2 = "bar" }'
