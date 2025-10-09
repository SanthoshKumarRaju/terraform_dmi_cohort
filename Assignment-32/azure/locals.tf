locals {
  env_config = {
    dev = {
      location       = "Central US"  # Changed region
      vm_size        = "Standard_B1s"
      allowed_ip     = "0.0.0.0/0"
      instance_count = 1
    }
    prod = {
      location       = "Central US"  # Changed region
      vm_size        = "Standard_B2s"
      allowed_ip     = "0.0.0.0/0"
      instance_count = 2
    }
  }

  default_config = local.env_config["dev"]
  current_config = lookup(local.env_config, terraform.workspace, local.default_config)
  
  current_env = terraform.workspace
  location    = local.current_config.location
  
  name_prefix = "${local.current_env}-epicbook"
  
  common_tags = {
    Environment = local.current_env
    Project     = "EpicBook"
    ManagedBy   = "Terraform"
    Workspace   = local.current_env
  }
}
