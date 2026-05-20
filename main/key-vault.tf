# Get current Azure client configuration
data "azurerm_client_config" "current" {}

# Key Vault using Azure Verified Module
module "key_vault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.2"

  name                            = "kv-${var.environment}-${local.resource_suffix}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  tenant_id                       = data.azurerm_client_config.current.tenant_id
  sku_name                        = var.key_vault_sku_name
  enabled_for_disk_encryption     = true
  enabled_for_deployment          = true
  enabled_for_template_deployment = true
  purge_protection_enabled        = false # PoC only — enable in production
  soft_delete_retention_days      = 7    # PoC only — use 90 in production
  public_network_access_enabled   = true

  network_acls = {
    bypass         = "AzureServices"
    default_action = "Deny"
    ip_rules       = var.key_vault_allowed_ips
  }

  # Diagnostic settings
  diagnostic_settings = {
    to_law = {
      name                  = "to-law"
      workspace_resource_id = azurerm_log_analytics_workspace.main.id
      log_analytics_destination_type = "Dedicated"
    }
  }

  # Role assignments for App Service managed identity and Terraform runner
  role_assignments = {
    app_service_secrets_user = {
      role_definition_id_or_name = "Key Vault Secrets User"
      principal_id               = module.app_service.system_assigned_mi_principal_id
    }
    # Terraform runner needs Secrets Officer to create/update secrets during deployments
    terraform_secrets_officer = {
      role_definition_id_or_name = "Key Vault Secrets Officer"
      principal_id               = data.azurerm_client_config.current.object_id
    }
    # Certificates User role commented out - role may not exist in this subscription
    # app_service_certificates_user = {
    #   role_definition_id_or_name = "Key Vault Certificates User"
    #   principal_id               = module.app_service.system_assigned_mi_principal_id
    # }
  }

  tags = local.common_tags

  depends_on = [
    azurerm_resource_group.main,
    module.app_service,
    azurerm_log_analytics_workspace.main
  ]
}

# Key Vault Secrets User - Additional Linux web apps
resource "azurerm_role_assignment" "web_apps_kv" {
  for_each = module.web_apps

  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.system_assigned_mi_principal_id
}

# Key Vault Secrets User - Windows web apps
resource "azurerm_role_assignment" "windows_apps_kv" {
  for_each = azurerm_windows_web_app.windows_apps

  scope                = module.key_vault.resource_id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value.identity[0].principal_id
}

# Store SQL Managed Instance connection string in Key Vault - COMMENTED OUT (SQL MI disabled)
/*
resource "azurerm_key_vault_secret" "sql_connection_string" {
  name         = "sql-connection-string"
  value        = "Server=tcp:${azurerm_mssql_managed_instance.main.fqdn},1433;Initial Catalog=${azurerm_mssql_managed_database.main.name};Authentication=Active Directory Managed Identity;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
  key_vault_id = module.key_vault.resource_id

  depends_on = [
    module.key_vault,
    azurerm_mssql_managed_instance.main,
    azurerm_mssql_managed_database.main
  ]
}
*/

# Store Storage Account blob endpoint in Key Vault
# shared_access_key_enabled = false on the account; apps must authenticate via managed identity
resource "azurerm_key_vault_secret" "storage_blob_endpoint" {
  name         = "storage-blob-endpoint"
  value        = azurerm_storage_account.main.primary_blob_endpoint
  key_vault_id = module.key_vault.resource_id

  depends_on = [
    module.key_vault,
    azurerm_storage_account.main,
  ]
}



















