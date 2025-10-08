terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstatestg1759915223"  # Your ACTUAL storage account
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}