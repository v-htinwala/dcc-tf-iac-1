# ----------------------------------------------------------
# Windows App Service Plan (for legacy .NET Framework apps)
# ----------------------------------------------------------
module "app_service_plan_windows" {
  source  = "Azure/avm-res-web-serverfarm/azurerm"
  version = "1.0.0"

  # Naming follows same convention as Linux plan
  name                = "asp-windows-${var.environment}-${local.resource_suffix}"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  # IMPORTANT: Windows OS for .NET Framework apps
  os_type = "Windows"

  sku_name     = var.app_service_plan_sku_name
  worker_count = var.app_service_plan_instance_count

  zone_balancing_enabled = false

  tags = local.common_tags
}
