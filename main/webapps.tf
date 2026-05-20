# New we App Services (allows configuration for additional apps)
module "web_apps" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.22.0"

  # Only NEW apps here (do NOT include existing app yet)
  for_each = {
    app2 = {
      name = "corpredundancyretirement"
    }
  }

  dapr_config = var.dapr_config

  # REQUIRED FIELDS (from your working config)
  name      = "${each.value.name}-${var.environment}-${local.resource_suffix}"
  parent_id = azurerm_resource_group.main.id
  location  = azurerm_resource_group.main.location

  service_plan_resource_id = module.app_service_plan.resource_id

  kind    = "webapp"
  os_type = "Linux"

  https_only                    = true
  public_network_access_enabled = false

  site_config = {
    always_on                               = true
    ftps_state                              = "FtpsOnly"
    http2_enabled                           = true
    minimum_tls_version                     = "1.2"
    vnet_route_all_enabled                  = true
    container_registry_use_managed_identity = true

    application_stack = {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION" = "~3"
    "WEBSITE_RUN_FROM_PACKAGE"              = "1"
  }

  managed_identities = {
    system_assigned = true
  }

  # VNet Integration — required to reach Key Vault and Storage private endpoints
  virtual_network_subnet_id = local.vnet_subnets["snet-appservice-integration"]

  tags = local.common_tags

  depends_on = [
    module.app_service_plan,
    azurerm_application_insights.main,
    azurerm_subnet_network_security_group_association.appservice_integration
  ]
}
# Deployment Slots for each web app
resource "azurerm_linux_web_app_slot" "staging" {
  for_each = module.web_apps

  name           = "staging"
  app_service_id = each.value.resource_id

  site_config {
    application_stack {
      dotnet_version = "8.0"
    }
  }

  app_settings = {
    "ASPNETCORE_ENVIRONMENT" = "Staging"
  }
}



