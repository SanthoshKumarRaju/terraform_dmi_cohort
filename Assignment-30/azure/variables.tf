variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "demo-rg"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}