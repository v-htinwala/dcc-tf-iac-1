# General Outputs
output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# Network Outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = local.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = local.vnet_name
}

output "subnet_ids" {
  description = "IDs of all subnets"
  value = {
    appgw_subnet              = local.vnet_subnets["snet-appgw"]
    appservice_integration    = local.vnet_subnets["snet-appservice-integration"]
    sql_managed_instance      = local.vnet_subnets["snet-sql-mi"]
    private_endpoint          = local.vnet_subnets["snet-private-endpoints"]
  }
}

# Application Gateway Outputs
output "application_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "appgw_private_ip" {
  description = "Internal App Gateway IP"
  value       = var.appgw_private_ip_address
}


# App Service Outputs
output "app_service_id" {
  description = "ID of the App Service"
  value       = module.app_service.resource_id
  sensitive   = true
}

output "app_service_default_hostname" {
  description = "Default hostname for the App Service"
  value       = module.app_service.resource_uri
  sensitive   = true
}

output "app_service_managed_identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = module.app_service.system_assigned_mi_principal_id
  sensitive   = true
}

# SQL Database Outputs - COMMENTED OUT (SQL blocked by policy)
/*
output "sql_server_id" {
  description = "ID of the SQL Server"
  value       = azurerm_mssql_server.main.id
  sensitive   = true
}

output "sql_server_fqdn" {
  description = "Fully Qualified Domain Name of the SQL Server"
  value       = azurerm_mssql_server.main.fully_qualified_domain_name
  sensitive   = true
}

output "sql_database_id" {
  description = "ID of the SQL Database"
  value       = azurerm_mssql_database.main.id
  sensitive   = true
}

output "sql_database_name" {
  description = "Name of the SQL Database"
  value       = azurerm_mssql_database.main.name
}
*/

# Key Vault Outputs
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.key_vault.resource_id
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.key_vault.uri
}

# Storage Account Outputs
output "storage_account_id" {
  description = "ID of the Storage Account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the Storage Account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the Storage Account"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

# Private Endpoint Outputs
output "private_endpoint_ids" {
  description = "IDs of all private endpoints"
  value = {
    app_service = azurerm_private_endpoint.app_service.id
    key_vault   = azurerm_private_endpoint.key_vault.id
    storage     = azurerm_private_endpoint.storage.id
    # sql_server  = azurerm_private_endpoint.sql_server.id  # COMMENTED OUT (SQL blocked by policy)
  }
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics Workspace"
  value       = azurerm_log_analytics_workspace.main.id
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.main.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Connection string for Application Insights"
  value       = azurerm_application_insights.main.connection_string
  sensitive   = true
}

