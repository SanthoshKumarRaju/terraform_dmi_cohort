# modules/network/outputs.tf
output "vnet_id" {
  description = "Virtual Network ID"
  value       = azurerm_virtual_network.main.id
}

output "public_subnet_id" {
  description = "Public subnet ID"
  value       = azurerm_subnet.public.id
}

output "mysql_subnet_id" {
  description = "MySQL subnet ID"
  value       = azurerm_subnet.mysql.id
}

output "public_nsg_id" {
  description = "Public Network Security Group ID"
  value       = azurerm_network_security_group.public.id
}