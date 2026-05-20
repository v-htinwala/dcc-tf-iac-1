# Private Endpoint for App Service
resource "azurerm_private_endpoint" "app_service" {
  name                = "pe-appservice-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = local.vnet_subnets["snet-private-endpoints"]

  private_service_connection {
    name                           = "psc-appservice"
    private_connection_resource_id = module.app_service.resource_id
    is_manual_connection           = false
    subresource_names              = ["sites"]
  }

  private_dns_zone_group {
    name                 = "pdns-group-appservice"
    private_dns_zone_ids = [azurerm_private_dns_zone.appservice.id]
  }

  tags = local.common_tags

  depends_on = [
    module.app_service,
    azurerm_private_dns_zone.appservice
  ]
}

# Note: SQL Managed Instance does not require a separate private endpoint
# as it is deployed directly into the VNet subnet (snet-sql-mi)

# Private Endpoint for Key Vault
resource "azurerm_private_endpoint" "key_vault" {
  name                = "pe-keyvault-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = local.vnet_subnets["snet-private-endpoints"]

  private_service_connection {
    name                           = "psc-keyvault"
    private_connection_resource_id = module.key_vault.resource_id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "pdns-group-keyvault"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }

  tags = local.common_tags

  depends_on = [
    module.key_vault,
    azurerm_private_dns_zone.keyvault
  ]
}

# Private Endpoint for Storage Account (Blob)
resource "azurerm_private_endpoint" "storage" {
  name                = "pe-storage-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = local.vnet_subnets["snet-private-endpoints"]

  private_service_connection {
    name                           = "psc-storage"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names              = ["blob"]
  }

  private_dns_zone_group {
    name                 = "pdns-group-storage"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage.id]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_storage_account.main,
    azurerm_private_dns_zone.storage
  ]
}

# Private Endpoint for SQL Server - COMMENTED OUT (SQL blocked by policy)
/*
resource "azurerm_private_endpoint" "sql_server" {
  name                = "pe-sqlserver-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = local.vnet_subnets["snet-private-endpoints"]

  private_service_connection {
    name                           = "psc-sqlserver"
    private_connection_resource_id = azurerm_mssql_server.main.id
    is_manual_connection           = false
    subresource_names              = ["sqlServer"]
  }

  private_dns_zone_group {
    name                 = "pdns-group-sqlserver"
    private_dns_zone_ids = [azurerm_private_dns_zone.sql.id]
  }

  tags = local.common_tags

  depends_on = [
    azurerm_mssql_server.main,
    azurerm_private_dns_zone.sql
  ]
}
*/

# Network Interface Details for Private Endpoints (for reference)
data "azurerm_private_endpoint_connection" "app_service" {
  name                = azurerm_private_endpoint.app_service.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_private_endpoint.app_service]
}

data "azurerm_private_endpoint_connection" "key_vault" {
  name                = azurerm_private_endpoint.key_vault.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_private_endpoint.key_vault]
}

data "azurerm_private_endpoint_connection" "storage" {
  name                = azurerm_private_endpoint.storage.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_private_endpoint.storage]
}

# SQL Server private endpoint connection data - COMMENTED OUT (SQL blocked by policy)
/*
data "azurerm_private_endpoint_connection" "sql_server" {
  name                = azurerm_private_endpoint.sql_server.name
  resource_group_name = azurerm_resource_group.main.name

  depends_on = [azurerm_private_endpoint.sql_server]
}
*/
