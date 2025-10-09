terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate8ee2535a"
    container_name       = "tfstate"
    key                  = "epicbook.terraform.tfstate"
  }
}