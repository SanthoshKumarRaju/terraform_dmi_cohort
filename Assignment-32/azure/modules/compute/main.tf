# Generate SSH key pair if not provided
resource "tls_private_key" "vm_ssh" {
  count     = var.ssh_public_key == "" ? 1 : 0
  algorithm = "RSA"
  rsa_bits  = 4096
}

locals {
  ssh_public_key_content = var.ssh_public_key != "" ? var.ssh_public_key : tls_private_key.vm_ssh[0].public_key_openssh
}

# Public IPs
resource "azurerm_public_ip" "main" {
  count               = var.instance_count
  name                = "${var.name_prefix}-vm-ip-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network Interfaces
resource "azurerm_network_interface" "main" {
  count               = var.instance_count
  name                = "${var.name_prefix}-nic-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main[count.index].id
  }
}

# Virtual Machines
resource "azurerm_linux_virtual_machine" "main" {
  count               = var.instance_count
  name                = "${var.name_prefix}-vm-${count.index}"
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.vm_size
  admin_username      = var.admin_username
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = local.ssh_public_key_content
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Simple custom data that installs nginx and creates a basic page
  custom_data = base64encode(<<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "<h1>EpicBook v1.0.0 - Instance ${count.index}</h1>" > /var/www/html/index.html
    echo "<p>Welcome to EpicBook!</p>" >> /var/www/html/index.html
    echo "<p>Deployed using Terraform</p>" >> /var/www/html/index.html
  EOT
  )

  lifecycle {
    ignore_changes = [custom_data]
  }
}
