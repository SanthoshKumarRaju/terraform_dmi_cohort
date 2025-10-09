output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "vm_name" {
  description = "Name of the virtual machine"
  value       = azurerm_linux_virtual_machine.main.name
}

output "public_ip_address" {
  description = "Public IP address of the VM"
  value       = azurerm_public_ip.main.ip_address
}

output "application_url" {
  description = "URL to access the React application"
  value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "test_url" {
  description = "URL to test page"
  value       = "http://${azurerm_public_ip.main.ip_address}/test.html"
}

output "environment" {
  description = "Current workspace/environment"
  value       = local.workspace_name
}

output "deployment_status" {
  description = "Deployment status"
  value       = "VM deployed. React app installation may take 3-5 minutes via custom data script."
}