# Log Analytics Workspace
resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = 30

  tags = local.common_tags
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "appi-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = azurerm_log_analytics_workspace.main.id
  application_type    = var.application_insights_type

  tags = local.common_tags
}

# Diagnostic Settings for Application Gateway
resource "azurerm_monitor_diagnostic_setting" "application_gateway" {
  name                       = "diag-appgw-${var.environment}"
  target_resource_id         = azurerm_application_gateway.main.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "ApplicationGatewayAccessLog"
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"
  }

  enabled_log {
    category = "ApplicationGatewayFirewallLog"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# Diagnostic Settings for Network Security Groups
resource "azurerm_monitor_diagnostic_setting" "nsg_appgw" {
  name                       = "diag-nsg-appgw-${var.environment}"
  target_resource_id         = azurerm_network_security_group.appgw.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_appservice" {
  name                       = "diag-nsg-appservice-${var.environment}"
  target_resource_id         = azurerm_network_security_group.appservice_integration.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

resource "azurerm_monitor_diagnostic_setting" "nsg_privateendpoints" {
  name                       = "diag-nsg-pe-${var.environment}"
  target_resource_id         = azurerm_network_security_group.private_endpoints.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# Action Group for Alerts
resource "azurerm_monitor_action_group" "main" {
  name                = "ag-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  short_name          = "ag-${var.environment}"

  tags = local.common_tags
}

# Alert Rule - Application Gateway Unhealthy Host Count
resource "azurerm_monitor_metric_alert" "appgw_unhealthy_host" {
  name                = "alert-appgw-unhealthy-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_application_gateway.main.id]
  description         = "Alert when Application Gateway has unhealthy backend hosts"
  severity            = 1
  frequency           = "PT1M"
  window_size         = "PT5M"

  criteria {
    metric_namespace = "Microsoft.Network/applicationGateways"
    metric_name      = "UnhealthyHostCount"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 0
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Alert Rule - App Service Response Time
resource "azurerm_monitor_metric_alert" "app_service_response_time" {
  name                = "alert-appservice-responsetime-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [module.app_service.resource_id]
  description         = "Alert when App Service response time is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Web/sites"
    metric_name      = "HttpResponseTime"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 5
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}

# Alert Rule - SQL Managed Instance storage usage - COMMENTED OUT (SQL MI disabled)
/*
resource "azurerm_monitor_metric_alert" "sql_mi_storage" {
  name                = "alert-sql-mi-storage-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  scopes              = [azurerm_mssql_managed_instance.main.id]
  description         = "Alert when SQL Managed Instance storage usage is high"
  severity            = 2
  frequency           = "PT5M"
  window_size         = "PT15M"

  criteria {
    metric_namespace = "Microsoft.Sql/managedInstances"
    metric_name      = "storage_space_used_mb"
    aggregation      = "Average"
    operator         = "GreaterThan"
    threshold        = 25600  # 80% of 32GB
  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }

  tags = local.common_tags
}
*/
