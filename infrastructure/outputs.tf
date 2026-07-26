output "resource_group_name" {
  description = "Name of the Azure resource group."
  value       = azurerm_resource_group.main.name
}

output "deployment_location" {
  description = "Azure region where the resources were deployed."
  value       = azurerm_resource_group.main.location
}

output "virtual_machine_name" {
  description = "Name of the Windows virtual machine."
  value       = azurerm_windows_virtual_machine.web.name
}

output "public_ip_address" {
  description = "Public IP address assigned to the IIS virtual machine."
  value       = azurerm_public_ip.web.ip_address
}

output "website_url" {
  description = "Public URL of the IIS website."
  value       = "http://${azurerm_public_ip.web.ip_address}"
}

output "rdp_connection_address" {
  description = "Public address for an approved RDP connection."
  value       = azurerm_public_ip.web.ip_address
}