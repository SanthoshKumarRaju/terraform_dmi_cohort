terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      # optionally pin version
      version = ">= 3.0.0"
    }
  }
  required_version = ">= 1.5.0"
}

provider "azurerm" {
  features {}
  # DO NOT put subscription id here; provider will read ARM_SUBSCRIPTION_ID
}

resource "azurerm_resource_group" "rg" {
  name     = "rg-tf-sp-demo"
  location = "East US"
}

output "rg_name" {
  value = azurerm_resource_group.rg.name
}

