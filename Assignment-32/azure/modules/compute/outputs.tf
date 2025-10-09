output "vm_ids" {
  description = "Virtual Machine IDs"
  value       = azurerm_linux_virtual_machine.main[*].id
}

output "vm_public_ips" {
  description = "Public IP addresses of the VMs"
  value       = azurerm_public_ip.main[*].ip_address
}

output "ssh_private_key" {
  description = "SSH private key (if generated)"
  value       = try(tls_private_key.vm_ssh[0].private_key_openssh, null)
  sensitive   = true
}
