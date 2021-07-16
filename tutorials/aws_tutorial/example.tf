terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  //profile = "default"
  region     = var.region
  # access_key = var.access_key
  # secret_key = var.secret_key
}

resource "aws_instance" "example" {
  ami           = var.amis[var.region]
  instance_type = var.instance_type

  key_name  = "example-keypair"
  user_data     = <<EOT
#cloud-config
# update apt on boot
package_update: true
# install nginx
packages:
- nginx
write_files:
- content: |
    <!DOCTYPE html>
    <html>
    <head>
      <title>StackPath - Amazon Web Services Instance</title>
      <meta http-equiv="Content-Type" content="text/html;charset=UTF-8">
      <style>
        html, body {
          background: #000;
          height: 100%;
          width: 100%;
          padding: 0;
          margin: 0;
          display: flex;
          justify-content: center;
          align-items: center;
          flex-flow: column;
        }
        img { width: 250px; }
        svg { padding: 0 40px; }
        p {
          color: #fff;
          font-family: 'Courier New', Courier, monospace;
          text-align: center;
          padding: 10px 30px;
        }
      </style>
    </head>
    <body>
      <img src="http://i.imgur.com/lOWEsJF.gif">
      <p><strong>Here we are!!!</strong></p>
    </body>
    </html>
  path: /usr/share/app/index.html
  permissions: '0644'
runcmd:
- sudo cp /usr/share/app/index.html /var/www/html/index.html
EOT

}

output "ip" {
  value = aws_instance.example.public_ip
}

// terraform apply -var 'amis={ us-east-1 = "foo", us-west-2 = "bar" }'
