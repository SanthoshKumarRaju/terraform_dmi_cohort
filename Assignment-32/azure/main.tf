
# Generate random password if not provided
resource "random_password" "vm_password" {
  length           = 16
  special          = true
  override_special = "!_%@"
}

# Use provided password or generate random one
locals {
  final_admin_password = coalesce(var.admin_password, random_password.vm_password.result)
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.name_prefix}-rg"
  location = local.location
  tags     = local.common_tags
}

# Network Module
module "network" {
  source = "./modules/network"

  resource_group_name = azurerm_resource_group.main.name
  location           = local.location
  name_prefix        = local.name_prefix
  allowed_ip         = local.current_config.allowed_ip
  tags               = local.common_tags
}

# Compute Module (without database dependencies)
module "compute" {
  source = "./modules/compute"

  resource_group_name = azurerm_resource_group.main.name
  location           = local.location
  name_prefix        = local.name_prefix
  vm_size            = local.current_config.vm_size
  admin_username     = var.admin_username
  admin_password     = local.final_admin_password
  ssh_public_key     = var.vm_ssh_public_key
  subnet_id          = module.network.public_subnet_id
  instance_count     = local.current_config.instance_count
  tags               = local.common_tags
}