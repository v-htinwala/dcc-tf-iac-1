# Public IP for Application Gateway (Standard SKU required by WAF_v2).
# No listener is attached to this frontend — the IP is allocated but effectively
# unreachable because the Application Gateway will not route any traffic from it.
resource "azurerm_public_ip" "appgw" {
  name                = "pip-appgw-${var.environment}-${local.resource_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = local.common_tags
  lifecycle {
    ignore_changes = [zones,ip_address,ip_tags]
  }

}

module "application_gateway_policy" {
  source              = "Azure/avm-res-network-applicationgatewaywebapplicationfirewallpolicy/azurerm"
  version             = "0.2.0"
  name                  =  "appgw-policy-${var.environment}-${local.resource_suffix}"
  policy_settings = {
    enabled                                   = false
    file_upload_limit_in_mb                   = 100
    js_challenge_cookie_expiration_in_minutes = 5
    max_request_body_size_in_kb               = 128
    mode                                      = "Prevention"
    request_body_check                        = true
    request_body_inspect_limit_in_kb          = 128
  }
  custom_rules = {
    example_rule_1 = {
    name      = "BlockSpecificIP"
    priority  = 1
    rule_type = "MatchRule"

    match_conditions = {
         condition_1 = {
      match_variables = [{
        variable_name = "RemoteAddr"
      }]
      operator           = "IPMatch"
      negation_condition = false
      match_values       = ["192.168.1.1"] # Replace with the IP address to block
    }
    }
    action = "Block"
    }
  }
  managed_rules = {
    managed_rule_set = {
        example_rule_set = {
            type    = "OWASP"
            version = "3.2"
        }
    }
    exclusion = {}
  }

  location              = azurerm_resource_group.main.location
  resource_group_name   = azurerm_resource_group.main.name
  tags =  local.common_tags
    depends_on = [azurerm_resource_group.main]
}

resource "azurerm_application_gateway" "main" {
  name                = "appgw-${var.environment}-${local.resource_suffix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  sku {
    name     = var.appgw_sku_name
    tier     = var.appgw_sku_tier
    capacity = var.appgw_capacity
  }

  # WAF configuration — required when tier is WAF_v2.
  # Prevention mode: actively blocks requests matching OWASP rules.
  # waf_configuration {
  #   enabled          = true
  #   firewall_mode    = var.appgw_waf_mode
  #   rule_set_type    = "OWASP"
  #   rule_set_version = var.appgw_waf_rule_set_version
  # }
  firewall_policy_id = module.application_gateway_policy.resource_id

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = local.vnet_subnets["snet-appgw"]
  }

  frontend_port {
    name = "frontend-http"
    port = 80
  }

  # Private frontend — the only frontend referenced by a listener.
  # All routing rules point here; this is the active ingress path.
  frontend_ip_configuration {
    name                          = "frontend-ip-configuration"
    subnet_id                     = local.vnet_subnets["snet-appgw"]
    private_ip_address_allocation = "Static"
    private_ip_address            = var.appgw_private_ip_address
  }

  # Public frontend — IP is allocated but NO listener references this configuration.
  # Traffic arriving on the public IP will be silently dropped by the gateway.
  frontend_ip_configuration {
    name                 = "frontend-public-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool {
    name  = "backend-pool-appservice"
    fqdns = [module.app_service.resource_uri]
  }

  backend_http_settings {
    name                                = "backend-http-settings"
    protocol                            = "Https"
    port                                = 443
    cookie_based_affinity               = "Disabled"
    request_timeout                     = 60
    pick_host_name_from_backend_address = true
    probe_name                          = "health-probe"
  }

  http_listener {
    name                           = "listener-internal"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "frontend-http"
    protocol                       = "Http"

    host_name = "randr.webappdev.derbyshire.local"
  }

  request_routing_rule {
    name                       = "routing-rule-internal"
    rule_type                  = "Basic"
    http_listener_name         = "listener-internal"
    backend_address_pool_name  = "backend-pool-appservice"
    backend_http_settings_name = "backend-http-settings"
    priority                   = 100
  }

  probe {
    name                                      = "health-probe"
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-399"]
    }
  }

  tags = local.common_tags

  depends_on = [
    module.vnet,
    module.app_service,
    azurerm_public_ip.appgw
  ]
}
