variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "ssh_public_key" {
  description = "SSH public key for EC2 instance access"
  type        = string
}

variable "environment_config" {
  description = "Configuration per environment"
  type = map(object({
    instance_name_prefix = string
    tags                 = map(string)
  }))
  default = {
    dev = {
      instance_name_prefix = "dev-react-app"
      tags = {
        Environment = "Development"
        Project     = "ReactApp"
        Team        = "DevTeam"
        Workspace   = "dev"
      }
    }
    prod = {
      instance_name_prefix = "prod-react-app"
      tags = {
        Environment = "Production"
        Project     = "ReactApp"
        Team        = "ProdTeam"
        Critical    = "true"
        Workspace   = "prod"
      }
    }
  }
}