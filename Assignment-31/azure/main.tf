terraform {
  required_version = ">= 1.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }

  backend "local" {}
}

provider "azurerm" {
  features {}
}

# Get current workspace
locals {
  workspace_name = terraform.workspace
  env_config     = var.environment_config[local.workspace_name]
  
  # Common naming convention
  vm_name = "${local.env_config.vm_name_prefix}-${random_id.vm_suffix.hex}"
}

# Random suffix for unique resource names
resource "random_id" "vm_suffix" {
  byte_length = 4
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = local.env_config.resource_group
  location = var.location
  tags     = local.env_config.tags
}

# Virtual Network
resource "azurerm_virtual_network" "main" {
  name                = "vnet-${local.workspace_name}-react"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.env_config.tags

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }
}

# Subnet - Explicitly depends on virtual network
resource "azurerm_subnet" "main" {
  name                 = "snet-${local.workspace_name}-react"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]

  # Explicit dependency to ensure VNET is fully created
  depends_on = [azurerm_virtual_network.main]

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }
}

# Network Security Group
resource "azurerm_network_security_group" "main" {
  name                = "nsg-${local.workspace_name}-react"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.env_config.tags

  security_rule {
    name                       = "HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }
}

# Public IP - Using Standard SKU
resource "azurerm_public_ip" "main" {
  name                = "pip-${local.workspace_name}-react"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  domain_name_label   = "${local.env_config.dns_label}-${random_id.vm_suffix.hex}"
  sku                 = "Standard"
  tags                = local.env_config.tags

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }
}

# Network Interface - Explicit dependencies on all network resources
resource "azurerm_network_interface" "main" {
  name                = "nic-${local.workspace_name}-react"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.env_config.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }

  # Explicit dependencies to ensure all network resources are ready
  depends_on = [
    azurerm_subnet.main,
    azurerm_public_ip.main,
    azurerm_network_security_group.main
  ]

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }
}

# Connect NSG to NIC
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.main.id
  network_security_group_id = azurerm_network_security_group.main.id

  depends_on = [azurerm_network_interface.main]
}

# Virtual Machine - Final resource with all dependencies
resource "azurerm_linux_virtual_machine" "main" {
  name                = local.vm_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.vm_size
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  tags                = local.env_config.tags

  disable_password_authentication = false

  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  # Custom data script to deploy React app
  custom_data = base64encode(templatefile("${path.module}/scripts/deploy-react-app.sh", {
    environment = local.workspace_name
  }))

  # Ensure all network dependencies are ready
  depends_on = [
    azurerm_network_interface_security_group_association.main
  ]

  timeouts {
    create = "30m"
    delete = "30m"
    read   = "5m"
    update = "30m"
  }
}