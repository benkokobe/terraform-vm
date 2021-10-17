terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
    }
  }
  backend "azurerm" {
    resource_group_name   = "bko-state"
    storage_account_name  = "bkostate"
    container_name        = "tstate"
    key                   = "bko.tfstate"
    }
}


provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "main" {
  name                = "${var.prefix}-pip"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "main" {
  name                = "${var.prefix}-nic"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  name                            = "${var.prefix}-vm"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_F2"
  admin_username                  = var.vm_user
  admin_password                  = var.vm_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main.id,
  ]

#   source_image_reference {
#     publisher = "Canonical"
#     offer     = "UbuntuServer"
#     sku       = "16.04-LTS"
#     version   = "latest"
#   }

  source_image_reference {
    publisher = "OpenLogic"
    offer     = "CentOS"
    sku       = "8_1"
    version   = "latest"
  }

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }


  provisioner "remote-exec" {
    
    inline = [
      "set -x",
      "ls -la /tmp"
    ]

    connection {
      host     = self.public_ip_address
      user     = self.admin_username
      password = self.admin_password
    }
  }
}
###################### Launch init script ##################################

resource "null_resource" "init-vm" {
  depends_on = [azurerm_linux_virtual_machine.main]
  connection {
    #type     = "ssh"
    #host     = azurerm_public_ip.ansible_public_ip.fqdn
    #host     = self.public_ip_address
    host      = azurerm_public_ip.main.ip_address
    user      = var.vm_user
    password  = var.vm_password
    #agent    = "false"
  }

  provisioner "remote-exec" {
    inline = [
      "set -x",
      "mkdir -p /tmp/scripts"
    ]
  }

  provisioner "file" {
    source      = "scripts/"
    destination = "/tmp/scripts/"
  }

  # mount drive
  provisioner "remote-exec" {
    inline = [
      "echo ${var.vm_password} | sudo -S --preserve-env sh /tmp/scripts/vm_init.sh"
    ]
  }
}