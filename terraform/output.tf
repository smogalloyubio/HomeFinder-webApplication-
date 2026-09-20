output "resource_group_name" {
  value = data.azurerm_resource_group.talos.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.talos.location
}

output "vnet_name" {
  value = azurerm_virtual_network.talos.name
}

output "vnet_id" {
  value = azurerm_virtual_network.talos.id
}

output "control_plane_subnet_id" {
  value = azurerm_subnet.control_plane.id
}

output "worker_subnet_id" {
  value = azurerm_subnet.worker.id
}

output "application_gateway_subnet_id" {
  value = azurerm_subnet.application_gateway.id
}


output "nat_gateway_id" {
  value = azurerm_nat_gateway.talos.id
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat_gateway.ip_address
}