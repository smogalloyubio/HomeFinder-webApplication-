resource "azurerm_resource_group" "aks" {
  name     = var.resource_group_name
  location =var.location 
}


resource "azurerm_virtual_network" "aks" {
  name                = "vnet-${var.cluster_name}"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  address_space = var.vnet_address_space
}


resource "azurerm_subnet" "public" {
  name                 = "snet-public"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name

  address_prefixes = [
    var.public_subnet_address_prefix
  ]
}

resource "azurerm_subnet" "aks" {
  name                 = "snet-aks-private"
  resource_group_name  = azurerm_resource_group.aks.name
  virtual_network_name = azurerm_virtual_network.aks.name

  address_prefixes = [
    var.aks_subnet_address_prefix
  ]
}


resource "azurerm_public_ip" "nat" {
  name                = "pip-${var.cluster_name}-nat"
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  allocation_method = "Static"
  sku               = "Standard"
}

resource "azurerm_nat_gateway" "aks" {
  name                = "nat-${var.cluster_name}"

  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name

  sku_name = "Standard"
}

resource "azurerm_nat_gateway_public_ip_association" "aks" {
  nat_gateway_id       = azurerm_nat_gateway.aks.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "aks" {
  subnet_id      = azurerm_subnet.aks.id
  nat_gateway_id = azurerm_nat_gateway.aks.id
}


resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}





resource "azurerm_kubernetes_cluster" "aks" {
  name                = var.cluster_name
  location            = azurerm_resource_group.aks.location
  resource_group_name = azurerm_resource_group.aks.name
  dns_prefix          = var.cluster_name

  kubernetes_version = null

  default_node_pool {
    name           = "system"
    node_count     = var.node_count
    vm_size        = var.vm_size
    vnet_subnet_id = azurerm_subnet.aks.id

    type = "VirtualMachineScaleSets"
  }

  identity {
    type = "SystemAssigned"
  }

node_provisioning_profile {
  mode = "Auto"
}
  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    network_policy      = "azure"

    load_balancer_sku = "standard"

    outbound_type = "userAssignedNATGateway"
  }

  role_based_access_control_enabled = true

  tags = {
    environment = "production"
    managed_by  = "terraform"
  }
}