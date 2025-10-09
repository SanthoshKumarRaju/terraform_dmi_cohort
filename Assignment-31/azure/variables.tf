variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "vm_size" {
  description = "Virtual Machine size"
  type        = string
  default     = "Standard_B1s"
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VM"
  type        = string
  sensitive   = true
}

variable "environment_config" {
  description = "Configuration per environment"
  type = map(object({
    vm_name_prefix    = string
    resource_group    = string
    dns_label         = string
    tags              = map(string)
  }))
  default = {
    dev = {
      vm_name_prefix    = "dev-react-vm"
      resource_group    = "rg-dev-react-app"
      dns_label         = "dev-react-app"
      tags = {
        Environment = "Development"
        Project     = "ReactApp"
        Team        = "DevTeam"
      }
    }
    prod = {
      vm_name_prefix    = "prod-react-vm"
      resource_group    = "rg-prod-react-app"
      dns_label         = "prod-react-app"
      tags = {
        Environment = "Production"
        Project     = "ReactApp"
        Team        = "ProdTeam"
        Critical    = "true"
      }
    }
  }
}