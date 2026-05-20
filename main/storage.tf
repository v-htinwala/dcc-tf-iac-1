# Storage Account
resource "azurerm_storage_account" "main" {
  name                            = "st${var.environment}${local.resource_suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  account_tier                    = var.storage_account_tier
  account_replication_type        = var.storage_account_replication_type
  account_kind                    = "StorageV2"
  https_traffic_only_enabled      = true
  min_tls_version                 = "TLS1_2"
  public_network_access_enabled   = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false
  default_to_oauth_authentication = true

  blob_properties {
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }

    container_delete_retention_policy {
      days = 30
    }
  }

  network_rules {
    default_action             = "Deny"
    bypass                     = ["AzureServices"]
    virtual_network_subnet_ids = []
    ip_rules = var.storage_account_allowed_ips
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# Storage Container for App Service deployment
resource "azurerm_storage_container" "deployment" {
  name                  = "deployment"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Storage Container for Vulnerability Assessment
resource "azurerm_storage_container" "vulnerability_assessment" {
  name                  = "vulnerability-assessment"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Storage Container for Backup
resource "azurerm_storage_container" "backup" {
  name                  = "backup"
  storage_account_id    = azurerm_storage_account.main.id
  container_access_type = "private"
}

# Role Assignment - Grant App Service managed identity access to Storage Account
resource "azurerm_role_assignment" "app_service_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.app_service.system_assigned_mi_principal_id

  # Deterministic UUID to prevent duplicate role assignment errors on re-apply
  name = uuidv5(
    "url",
    "${azurerm_storage_account.main.id}-${module.app_service.system_assigned_mi_principal_id}-StorageBlobDataContributor"
  )
}

# Role Assignment - Additional Linux web apps managed identity access to Storage
resource "azurerm_role_assignment" "web_apps_storage" {
  for_each = module.web_apps

  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.system_assigned_mi_principal_id

  name = uuidv5(
    "url",
    "${azurerm_storage_account.main.id}-${each.value.system_assigned_mi_principal_id}-StorageBlobDataContributor"
  )
}

# Role Assignment - Windows web apps managed identity access to Storage
resource "azurerm_role_assignment" "windows_apps_storage" {
  for_each = azurerm_windows_web_app.windows_apps

  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = each.value.identity[0].principal_id

  name = uuidv5(
    "url",
    "${azurerm_storage_account.main.id}-${each.value.identity[0].principal_id}-StorageBlobDataContributor"
  )
}

# Role Assignment - SQL Server managed identity - COMMENTED OUT (SQL blocked by policy)
/*
resource "azurerm_role_assignment" "sql_server_storage" {
  scope                = azurerm_storage_account.main.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_mssql_server.main.identity[0].principal_id

  depends_on = [
    azurerm_mssql_server.main
  ]
}
*/

# Diagnostic Settings for Storage Account
resource "azurerm_monitor_diagnostic_setting" "storage_account" {
  name                       = "diag-storage-${var.environment}"
  target_resource_id         = azurerm_storage_account.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_metric {
    category = "Transaction"
  }
}

# Diagnostic Settings for Blob Service
resource "azurerm_monitor_diagnostic_setting" "storage_blob" {
  name                       = "diag-storage-blob-${var.environment}"
  target_resource_id         = "${azurerm_storage_account.main.id}/blobServices/default"
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "StorageRead"
  }

  enabled_log {
    category = "StorageWrite"
  }

  enabled_log {
    category = "StorageDelete"
  }

  enabled_metric {
    category = "Transaction"
  }
}







