# Create a simple resource group for demonstration
resource "azurerm_resource_group" "demo" {
  name     = "demo-rg-remote-state"
  location = "East US"
  
  tags = {
    environment = "demo"
    managed-by  = "terraform"
  }
}

# Add a storage account to make operations take longer for locking test
resource "azurerm_storage_account" "demo" {
  name                     = "demosa${random_integer.suffix.result}"
  resource_group_name      = azurerm_resource_group.demo.name
  location                 = azurerm_resource_group.demo.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  tags = {
    environment = "demo"
  }
}

resource "random_integer" "suffix" {
  min = 10000
  max = 99999
}