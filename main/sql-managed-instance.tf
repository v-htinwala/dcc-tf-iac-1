# ============================================================================
# SQL MANAGED INSTANCE - COMMENTED OUT
# Reason: Blocked by Azure Policy (MCAPS) - RequestDisallowedByPolicy
# To re-enable: Uncomment this file and corresponding outputs in outputs.tf
# ============================================================================

/*
# Route Table for SQL Managed Instance
resource "azurerm_route_table" "sql_mi" {
  name                          = "rt-sql-mi-${var.environment}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  bgp_route_propagation_enabled = true

  tags = local.common_tags
}

# Associate Route Table with SQL MI Subnet
resource "azurerm_subnet_route_table_association" "sql_mi" {
  subnet_id      = local.vnet_subnets["snet-sql-mi"]
  route_table_id = azurerm_route_table.sql_mi.id
}

# Azure SQL Managed Instance
resource "azurerm_mssql_managed_instance" "main" {
  name                         = "sqlmi-${var.environment}-${local.resource_suffix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  administrator_login          = var.sql_managed_instance_admin_username
  administrator_login_password = var.sql_managed_instance_admin_password
  
  license_type       = var.sql_managed_instance_license_type
  sku_name           = var.sql_managed_instance_sku_name
  storage_size_in_gb = var.sql_managed_instance_storage_size_gb
  subnet_id          = local.vnet_subnets["snet-sql-mi"]
  vcores             = var.sql_managed_instance_vcores

  # General Purpose properties
  storage_account_type = "LRS"
  
  # Security settings
  minimum_tls_version           = "1.2"
  public_data_endpoint_enabled  = false
  proxy_override                = "Default"
  timezone_id                   = "UTC"

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  depends_on = [
    azurerm_subnet_network_security_group_association.sql_mi,
    azurerm_subnet_route_table_association.sql_mi
  ]
}

# SQL Managed Instance Database
resource "azurerm_mssql_managed_database" "main" {
  name                = "sqlmidb-${var.environment}"
  managed_instance_id = azurerm_mssql_managed_instance.main.id

  # No point in time restore for PoC/test (no DR requirement)
  
  lifecycle {
    prevent_destroy = false
  }
}

# SQL Managed Instance Azure AD Administrator
resource "azurerm_mssql_managed_instance_active_directory_administrator" "main" {
  managed_instance_id = azurerm_mssql_managed_instance.main.id
  login_username      = "AzureAD Admin"
  object_id           = module.app_service.system_assigned_mi_principal_id
  tenant_id           = data.azurerm_client_config.current.tenant_id

  depends_on = [
    azurerm_mssql_managed_instance.main,
    module.app_service
  ]
}

# Enable Advanced Data Security for SQL Managed Instance
resource "azurerm_mssql_managed_instance_security_alert_policy" "main" {
  resource_group_name        = azurerm_resource_group.main.name
  managed_instance_name      = azurerm_mssql_managed_instance.main.name
  enabled                    = true
  storage_endpoint           = azurerm_storage_account.main.primary_blob_endpoint
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  retention_days             = 30

  depends_on = [
    azurerm_storage_account.main
  ]
}

# Enable Vulnerability Assessment
resource "azurerm_mssql_managed_instance_vulnerability_assessment" "main" {
  managed_instance_id        = azurerm_mssql_managed_instance.main.id
  storage_container_path     = "${azurerm_storage_account.main.primary_blob_endpoint}vulnerability-assessment/"
  storage_account_access_key = azurerm_storage_account.main.primary_access_key

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
  }

  depends_on = [
    azurerm_mssql_managed_instance_security_alert_policy.main,
    azurerm_storage_container.vulnerability_assessment
  ]
}
*/

# ============================================================================
# AZURE SQL DATABASE - Serverless Tier
# ============================================================================
# COMMENTED OUT: MCAPS Policy blocks SQL Database creation
# The subscription policy prevents deployment of SQL Server/Database resources
# Consider using Azure PostgreSQL/MySQL or deploying to a different subscription
# ============================================================================
/*
# Azure SQL Server (Logical Server)
resource "azurerm_mssql_server" "main" {
  name                         = "sql-${var.environment}-${local.resource_suffix}"
  resource_group_name          = azurerm_resource_group.main.name
  location                     = azurerm_resource_group.main.location
  version                      = "12.0"
  administrator_login          = var.sql_managed_instance_admin_username
  administrator_login_password = var.sql_managed_instance_admin_password
  minimum_tls_version          = "1.2"
  public_network_access_enabled = false

  azuread_administrator {
    login_username = "AzureAD Admin"
    object_id      = module.app_service.system_assigned_mi_principal_id
    tenant_id      = data.azurerm_client_config.current.tenant_id
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags

  depends_on = [
    module.app_service
  ]
}

# Azure SQL Database - Serverless Compute Tier
resource "azurerm_mssql_database" "main" {
  name      = "sqldb-${var.environment}"
  server_id = azurerm_mssql_server.main.id
  collation = "SQL_Latin1_General_CP1_CI_AS"
  
  # Serverless compute tier - auto-pauses when inactive
  sku_name                    = "GP_S_Gen5_2"  # General Purpose Serverless, Gen5, 2 vCores
  max_size_gb                 = 32
  auto_pause_delay_in_minutes = 60
  min_capacity                = 0.5
  
  # Security settings
  ledger_enabled = false
  
  # Backup settings
  short_term_retention_policy {
    retention_days = 7
  }

  long_term_retention_policy {
    weekly_retention  = "P1W"
    monthly_retention = "P1M"
  }

  tags = local.common_tags
}

# SQL Server Firewall Rule - Deny all public access
resource "azurerm_mssql_firewall_rule" "deny_all" {
  name             = "DenyAllPublicAccess"
  server_id        = azurerm_mssql_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# Enable Advanced Threat Protection
resource "azurerm_mssql_server_security_alert_policy" "main" {
  resource_group_name = azurerm_resource_group.main.name
  server_name         = azurerm_mssql_server.main.name
  state               = "Enabled"
  retention_days      = 30
}

# Enable Vulnerability Assessment for SQL Server
resource "azurerm_mssql_server_vulnerability_assessment" "main" {
  server_security_alert_policy_id = azurerm_mssql_server_security_alert_policy.main.id
  storage_container_path          = "${azurerm_storage_account.main.primary_blob_endpoint}vulnerability-assessment/"

  recurring_scans {
    enabled                   = true
    email_subscription_admins = true
  }

  depends_on = [
    azurerm_storage_container.vulnerability_assessment
  ]
}
*/
