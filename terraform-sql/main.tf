resource "azurerm_resource_group" "sql"{
    name = "rg-sql-learning"
    location= "eastus"

}

resource "azurerm_mssql_server" "sql" {
  name                         = "floci-sql-learning"
  resource_group_name          = azurerm_resource_group.sql.name
  location                     = azurerm_resource_group.sql.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
}

resource "azurerm_mssql_database" "database" {
  name      = "homefinder"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "Basic"
}