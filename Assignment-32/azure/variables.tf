variable "admin_username" {
  description = "Admin username for the VM and database"
  type        = string
  default     = "epicbookadmin"
}

variable "admin_password" {
  description = "Admin password for the VM and database"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name"
  type        = string
  default     = "epicbook"
}

variable "github_repo" {
  description = "GitHub repository for EpicBook application"
  type        = string
  default     = "https://github.com/example/epicbook.git"
}

variable "branch" {
  description = "Git branch to deploy"
  type        = string
  default     = "main"
}

variable "app_version" {
  description = "Version of the EpicBook application to deploy"
  type        = string
  default     = "v1.0.0"
}

variable "vm_ssh_public_key" {
  description = "SSH public key for VM access"
  type        = string
  default     = ""
}