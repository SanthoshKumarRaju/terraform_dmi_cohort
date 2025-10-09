output "resource_group_name" {
  description = "Resource group name"
  value       = azurerm_resource_group.main.name
}

output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = module.compute.vm_public_ips
}

output "application_urls" {
  description = "URLs to access the EpicBook application"
  value       = [for ip in module.compute.vm_public_ips : "http://${ip}"]
}

output "ssh_commands" {
  description = "SSH commands to connect to the VMs"
  value       = [for ip in module.compute.vm_public_ips : "ssh ${var.admin_username}@${ip}"]
}

output "workspace" {
  description = "Current Terraform workspace"
  value       = local.current_env
}

output "ssh_private_key" {
  description = "SSH private key"
  value       = module.compute.ssh_private_key
  sensitive   = true
}
