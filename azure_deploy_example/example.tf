# terraform {
#   required_providers {
#     azurerm = {
#       source  = "hashicorp/azurerm"
#       version = "=2.46.0"
#     }
#   }
# }

terraform {
  backend "remote" {
    organization = "BinaryStudio"

    workspaces {
      name = "test-workflow"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}

  # subscription_id = "00000000-0000-0000-0000-000000000000"
}

resource "azurerm_resource_group" "example_resource_group" {
  name     = "terraform-example-resources"
  location = "West Europe"
}

resource "azurerm_container_group" "example_container_group" {
  name                = "terraform-example"
  location            = azurerm_resource_group.example_resource_group.location
  resource_group_name = azurerm_resource_group.example_resource_group.name
  ip_address_type     = "public"
  dns_name_label      = "terraform-example"
  os_type             = "Linux"

  container {
    name   = "hello-world"
    image  = "microsoft/aci-helloworld:latest"
    cpu    = "0.5"
    memory = "1.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }

  container {
    name   = "sidecar"
    image  = "microsoft/aci-tutorial-sidecar"
    cpu    = "0.5"
    memory = "1.5"
  }

  tags = {
    environment = "dev"
  }
}

output "endpoint" {
  value = azurerm_container_group.example_container_group.fqdn
}