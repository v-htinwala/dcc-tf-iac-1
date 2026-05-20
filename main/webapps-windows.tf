# ----------------------------------------------------------
# Windows Web App (.NET Framework 4.5 / 4.8)
# ----------------------------------------------------------
resource "azurerm_windows_web_app" "windows_apps" {
  for_each = {
    rr = {
      name = "corp-redundancy-retirement-legacy"
    }
  }

  name                = "${each.value.name}-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # THIS links the app to your Windows plan
  service_plan_id = module.app_service_plan_windows.resource_id

  https_only                    = true
  public_network_access_enabled = false

  site_config {
    always_on           = true
    minimum_tls_version = "1.2"
    ftps_state          = "FtpsOnly"
  }

  app_settings = {
    "WEBSITE_RUN_FROM_PACKAGE"                    = "1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"      = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}


resource "azurerm_windows_web_app_slot" "staging" {
  for_each = azurerm_windows_web_app.windows_apps

  name           = "staging-1"
  app_service_id = each.value.id

  site_config {}
}
