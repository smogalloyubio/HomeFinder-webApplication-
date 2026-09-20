data "azurerm_resource_group" "talos" {
  name = var.resource_group_name
}

data "azurerm_storage_account" "store" {
  name                = "floci"
  resource_group_name = data.azurerm_resource_group.talos.name
}

resource "azurerm_user_assigned_identity" "image_builder" {
  name                = "id-talos-image-reader"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name
}

resource "azurerm_role_assignment" "storage_reader" {
  scope                = data.azurerm_storage_account.store.id
  role_definition_name = "Storage Blob Data Reader"
  principal_id         = azurerm_user_assigned_identity.image_builder.principal_id
}

resource "azurerm_virtual_network" "talos" {
  name                = "vnet-talos"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  address_space = ["10.0.0.0/16"]

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_subnet" "control_plane" {
  name                 = "snet-control-plane"
  resource_group_name  = data.azurerm_resource_group.talos.name
  virtual_network_name = azurerm_virtual_network.talos.name

  address_prefixes = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "worker" {
  name                 = "snet-worker"
  resource_group_name  = data.azurerm_resource_group.talos.name
  virtual_network_name = azurerm_virtual_network.talos.name

  address_prefixes = ["10.0.2.0/24"]
}

resource "azurerm_subnet" "application_gateway" {
  name                 = "snet-application-gateway"
  resource_group_name  = data.azurerm_resource_group.talos.name
  virtual_network_name = azurerm_virtual_network.talos.name

  address_prefixes = ["10.0.3.0/24"]
}

resource "azurerm_network_security_group" "control_plane" {
  name                = "nsg-control-plane"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_network_security_group" "worker" {
  name                = "nsg-worker"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_network_security_group" "application_gateway" {
  name                = "nsg-application-gateway"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_network_security_rule" "control_plane_k8s_api" {
  name                        = "allow-k8s-api-6443"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "6443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.talos.name
  network_security_group_name = azurerm_network_security_group.control_plane.name
}

resource "azurerm_network_security_rule" "control_plane_talos_api" {
  name                        = "allow-talos-api-cp-50000"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.talos.name
  network_security_group_name = azurerm_network_security_group.control_plane.name
}

resource "azurerm_network_security_rule" "worker_talos_api" {
  name                        = "allow-talos-api-worker-50000"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "50000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.talos.name
  network_security_group_name = azurerm_network_security_group.worker.name
}

resource "azurerm_network_security_rule" "worker_app_ingress" {
  name                        = "allow-app-gateway-to-workers-32080"
  priority                    = 101
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "32080"
  source_address_prefix       = "10.0.3.0/24"
  destination_address_prefix  = "*"
  resource_group_name         = data.azurerm_resource_group.talos.name
  network_security_group_name = azurerm_network_security_group.worker.name
}

resource "azurerm_subnet_network_security_group_association" "control_plane" {
  subnet_id                 = azurerm_subnet.control_plane.id
  network_security_group_id = azurerm_network_security_group.control_plane.id
}

resource "azurerm_subnet_network_security_group_association" "worker" {
  subnet_id                 = azurerm_subnet.worker.id
  network_security_group_id = azurerm_network_security_group.worker.id
}

resource "azurerm_subnet_network_security_group_association" "application_gateway" {
  subnet_id                 = azurerm_subnet.application_gateway.id
  network_security_group_id = azurerm_network_security_group.application_gateway.id
}

resource "azurerm_public_ip" "nat_gateway" {
  name                = "pip-nat-gateway"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_nat_gateway" "talos" {
  name                = "nat-talos"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  sku_name                = "Standard"
  idle_timeout_in_minutes = 10

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_nat_gateway_public_ip_association" "talos" {
  nat_gateway_id       = azurerm_nat_gateway.talos.id
  public_ip_address_id = azurerm_public_ip.nat_gateway.id
}

resource "azurerm_subnet_nat_gateway_association" "control_plane" {
  subnet_id      = azurerm_subnet.control_plane.id
  nat_gateway_id = azurerm_nat_gateway.talos.id
}

resource "azurerm_subnet_nat_gateway_association" "worker" {
  subnet_id      = azurerm_subnet.worker.id
  nat_gateway_id = azurerm_nat_gateway.talos.id
}

resource "azurerm_network_interface" "control_plane" {
  name                = "nic-talos-control-plane-1"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.control_plane.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project     = "talos-azure"
    environment = var.environment
    role        = "control-plane"
    managed_by  = "terraform"
  }
}

resource "azurerm_network_interface" "worker" {
  count               = 2
  name                = "nic-talos-worker-${count.index + 1}"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.worker.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project     = "talos-azure"
    environment = var.environment
    role        = "worker"
    managed_by  = "terraform"
  }
}

resource "azurerm_public_ip" "application_gateway" {
  name                = "pip-application-gateway"
  location            = data.azurerm_resource_group.talos.location
  resource_group_name = data.azurerm_resource_group.talos.name

  allocation_method = "Static"
  sku               = "Standard"

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_application_gateway" "talos" {
  name                = "appgw-talos"
  resource_group_name = data.azurerm_resource_group.talos.name
  location            = data.azurerm_resource_group.talos.location

  sku {
    name = "Standard_v2"
    tier = "Standard_v2"
  }

  autoscale_configuration {
    min_capacity = 1
    max_capacity = 2
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.application_gateway.id
  }

  frontend_ip_configuration {
    name                   = "appgw-public-frontend"
    public_ip_address_id = azurerm_public_ip.application_gateway.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  backend_address_pool {
    name = "talos-ingress-backend"
    ip_addresses = [
      for nic in azurerm_network_interface.worker : nic.private_ip_address
    ]
  }

  backend_http_settings {
    name                  = "nginx-ingress-http"
    cookie_based_affinity = "Disabled"
    port                  = 32080
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "appgw-public-frontend"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "route-to-nginx"
    priority                   = 100
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "talos-ingress-backend"
    backend_http_settings_name = "nginx-ingress-http"
  }
}

resource "azurerm_snapshot" "talos" {
  name                 = "snapshot-talos-vhd"
  location             = data.azurerm_resource_group.talos.location
  resource_group_name  = data.azurerm_resource_group.talos.name
  create_option        = "Import"
  source_uri           = "https://${data.azurerm_storage_account.store.name}.blob.core.windows.net/mystoragecontainer/azure-amd64.vhd"
  storage_account_id   = data.azurerm_storage_account.store.id

  depends_on = [
    azurerm_role_assignment.storage_reader
  ]

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_managed_disk" "control_plane" {
  name                 = "disk-talos-control-plane-1"
  location             = data.azurerm_resource_group.talos.location
  resource_group_name  = data.azurerm_resource_group.talos.name
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = azurerm_snapshot.talos.id
  disk_size_gb         = 30
  hyper_v_generation   = "V2"

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_managed_disk" "worker" {
  count                = 2
  name                 = "disk-talos-worker-${count.index + 1}"
  location             = data.azurerm_resource_group.talos.location
  resource_group_name  = data.azurerm_resource_group.talos.name
  storage_account_type = "Standard_LRS"
  create_option        = "Copy"
  source_resource_id   = azurerm_snapshot.talos.id
  disk_size_gb         = 30
  hyper_v_generation   = "V2"

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}

resource "azurerm_linux_virtual_machine" "control_plane" {
  name                  = "talos-control-plane-1"
  location              = data.azurerm_resource_group.talos.location
  resource_group_name   = data.azurerm_resource_group.talos.name
  size                  = "Standard_D2s_v5"
  network_interface_ids = [azurerm_network_interface.control_plane.id]
  admin_username        = "talos"

  disable_password_authentication = true
  os_managed_disk_id            = azurerm_managed_disk.control_plane.id

   os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  
  tags = {
    project     = "talos-azure"
    environment = var.environment
    role        = "control-plane"
    managed_by  = "terraform"
  }
}

resource "azurerm_linux_virtual_machine" "worker" {
  count                 = 2
  name                  = "talos-worker-${count.index + 1}"
  location              = data.azurerm_resource_group.talos.location
  resource_group_name   = data.azurerm_resource_group.talos.name
  size                  = "Standard_D2s_v5"
  network_interface_ids = [azurerm_network_interface.worker[count.index].id]
  admin_username        = "talos"

  disable_password_authentication = true
  os_managed_disk_id            = azurerm_managed_disk.worker[count.index].id


 os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }


  tags = {
    project     = "talos-azure"
    environment = var.environment
    role        = "worker"
    managed_by  = "terraform"
  }
}