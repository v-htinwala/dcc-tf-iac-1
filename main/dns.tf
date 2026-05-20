# Private DNS Zone for App Service
resource "azurerm_private_dns_zone" "appservice" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Private DNS Zone for SQL Database
resource "azurerm_private_dns_zone" "sql" {
  name                = "privatelink.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Private DNS Zone for SQL Managed Instance
resource "azurerm_private_dns_zone" "sql_mi" {
  name                = "privatelink.${azurerm_resource_group.main.location}.database.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Private DNS Zone for Key Vault
resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Private DNS Zone for Storage
resource "azurerm_private_dns_zone" "storage" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# VNet Link for App Service Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "appservice" {
  name                  = "vnet-link-appservice"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.appservice.name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# VNet Link for SQL Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "sql" {
  name                  = "vnet-link-sql"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql.name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# VNet Link for SQL Managed Instance Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "sql_mi" {
  name                  = "vnet-link-sql-mi"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_mi.name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# VNet Link for Key Vault Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "vnet-link-keyvault"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# VNet Link for Storage Private DNS Zone
resource "azurerm_private_dns_zone_virtual_network_link" "storage" {
  name                  = "vnet-link-storage"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.storage.name
  virtual_network_id    = local.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}
