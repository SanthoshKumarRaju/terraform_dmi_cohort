output "mysql_fqdn" {
  description = "MySQL Fully Qualified Domain Name"
  value       = azurerm_mysql_server.main.fqdn
}

output "database_name" {
  description = "Database name"
  value       = azurerm_mysql_database.main.name
}
