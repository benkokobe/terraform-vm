output "public_ip_address" {
  value = azurerm_public_ip.main.fqdn
}
output "location2" {
    value = azurerm_resource_group.main.location
    description = "Primary Location"
}

output "vnet_address_space" {
    value = azurerm_virtual_network.main.address_space
    description = "VNET Address Space"
}

output "fqdn" {
    value = azurerm_public_ip.main.fqdn
    description = "Fully Qualified Domain Name"
}

