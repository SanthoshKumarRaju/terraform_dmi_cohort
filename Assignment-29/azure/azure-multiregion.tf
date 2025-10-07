terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  alias    = "eastus"
  features {}
}

provider "azurerm" {
  alias    = "westeurope"
  features {}
}

# --- Random Suffixes ---
resource "random_id" "eastus_suffix" {
  byte_length = 3
}

resource "random_id" "westeurope_suffix" {
  byte_length = 3
}

# --- East US ---
resource "azurerm_resource_group" "eastus_rg" {
  provider = azurerm.eastus
  name     = "rg-dev-assets-eastus"
  location = "East US"

  tags = {
    project = "multicloud-foundation"
    owner   = "santhosh"
    env     = "dev"
  }
}

resource "azurerm_storage_account" "eastus_storage" {
  provider                 = azurerm.eastus
  name                     = "compdevassetseus${random_id.eastus_suffix.hex}"
  resource_group_name      = azurerm_resource_group.eastus_rg.name
  location                 = azurerm_resource_group.eastus_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    project = "multicloud-foundation"
    owner   = "santhosh"
    env     = "dev"
  }
}

# --- West Europe ---
resource "azurerm_resource_group" "westeurope_rg" {
  provider = azurerm.westeurope
  name     = "rg-dev-assets-westeurope"
  location = "West Europe"

  tags = {
    project = "multicloud-foundation"
    owner   = "santhosh"
    env     = "dev"
  }
}

resource "azurerm_storage_account" "westeurope_storage" {
  provider                 = azurerm.westeurope
  name                     = "compdevassetsweu${random_id.westeurope_suffix.hex}"
  resource_group_name      = azurerm_resource_group.westeurope_rg.name
  location                 = azurerm_resource_group.westeurope_rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    project = "multicloud-foundation"
    owner   = "santhosh"
    env     = "dev"
  }
}