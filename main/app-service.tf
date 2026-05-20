# App Service Plan using Azure Verified Module
module "app_service_plan" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "1.0.0"

  name                = "asp-${var.environment}-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  os_type               = "Linux"
  sku_name              = var.app_service_plan_sku_name
  worker_count          = var.app_service_plan_instance_count
  zone_balancing_enabled = false

  tags = local.common_tags
}

# App Service (Web App) using Azure Verified Module
module "app_service" {
  source  = "Azure/avm-res-web-site/azurerm"
  version = "0.22.0"

  dapr_config = var.dapr_config

  name                          = "app-ukwest-${var.environment}-${local.resource_suffix}"
  parent_id                     = azurerm_resource_group.main.id
  location                      = azurerm_resource_group.main.location
  kind                          = "webapp"
  os_type                       = "Linux"
  service_plan_resource_id      = module.app_service_plan.resource_id
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
    "APPINSIGHTS_INSTRUMENTATIONKEY"             = azurerm_application_insights.main.instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"       = azurerm_application_insights.main.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION"  = "~3"
    "WEBSITE_RUN_FROM_PACKAGE"                    = "1"
  }

  # Enable Managed Identity
  managed_identities = {
    system_assigned = true
  }

  # VNet Integration
  virtual_network_subnet_id = local.vnet_subnets["snet-appservice-integration"]

  tags = local.common_tags

  depends_on = [
    module.app_service_plan,
    azurerm_application_insights.main,
    azurerm_subnet_network_security_group_association.appservice_integration
  ]
}








