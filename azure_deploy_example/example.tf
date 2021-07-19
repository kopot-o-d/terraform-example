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

// comment here

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
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
    name   = "my-app"
    image  = "lecturedocker/frontend"
    cpu    = "0.5"
    memory = "0.5"

    ports {
      port     = 80
      protocol = "TCP"
    }
  }
}

output "endpoint" {
  value = azurerm_container_group.example_container_group.fqdn
}