resource "azurerm_resource_group" "talos" {
  name     = var.resource_group_name
  location = var.location

  tags = {
    project     = "talos-azure"
    environment = var.environment
    managed_by  = "terraform"
  }
}