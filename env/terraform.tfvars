# =============================================================================
# General Configuration
# =============================================================================
subscription_id     = "6e056983-3426-4ade-b14f-a1058dac2dfd"
resource_group_name = "rg-ukw-web-app-poc"
location            = "ukwest"
environment         = "poc"

tags = {
  Project     = "UK West App Service PoC"
  Environment = "PoC"
  CostCenter  = "LC30003"
  Owner       = "ICT Operations"
}

# =============================================================================
# Network Configuration
# =============================================================================
vnet_address_space                    =    ["172.29.110.0/24"] # This is the Vnet for the supports the DCC-SUB-WEB-DEV-Internal Websites Subscription
appgw_subnet_prefix                   =    "172.29.110.0/26"  # This subnet is for the Application Gateway
appservice_integration_subnet_prefix  =    "172.29.110.64/27" # This subnet is for the App Service VNet integration (delegated to Microsoft.Web/serverFarms)
sql_mi_subnet_prefix                  =    "172.29.110.96/27" # This subnet is for the SQL Managed Instance (delegated to Microsoft.Sql/managedInstances)
private_endpoint_subnet_prefix          =    "172.29.110.128/28"# Thisis subnet is for Private Endpoints (delegated to Microsoft.Network/privateEndpoints)

# =============================================================================
# Network peering Configuration
# =============================================================================
# hub_vnet_name                = "DCC-UKS-VNET-HUB"
# hub_vnet_resource_group_name = "DCC-RG-UKS-CON-Networks"
# spoke_vnet_name              = "vnet-poc-t5swwh"


# =============================================================================
# Application Gateway Configuration
# =============================================================================
appgw_sku_name              = "WAF_v2"
appgw_sku_tier              = "WAF_v2"
appgw_capacity              = 2
appgw_waf_mode              = "Prevention"
appgw_waf_rule_set_version  = "3.2"

# =============================================================================
# App Service Configuration
# Standard tier is minimum for VNet integration
# Single instance sufficient for PoC (UK West has no Availability Zones)
# =============================================================================
# app_service_name is now auto-generated in app-service.tf as app-ukwest-${environment}-${resource_suffix}
app_service_plan_sku_name      = "P0v3"
app_service_plan_instance_count = 1

# =============================================================================
# SQL Managed Instance Configuration
# DBA team advised: SQL MI supports all required functionality
# General Purpose tier: Budget-oriented, balanced, and scalable
# Minimum 4 vCores required, 32GB storage (current DB is 5GB)
# No DR for test/pilot
# NOTE: Update these values with secure credentials
# =============================================================================
sql_managed_instance_admin_username = "miadmin"
sql_managed_instance_admin_password = "M62gQz63x2hwyI!" # IMPORTANT: Change this!
sql_managed_instance_sku_name       = "GP_Gen5"
sql_managed_instance_vcores         = 4
sql_managed_instance_storage_size_gb = 32
sql_managed_instance_license_type   = "LicenseIncluded"

# =============================================================================
# Storage Account Configuration
# Zone-redundant storage not used (LRS for cost optimization)
# =============================================================================
storage_account_tier             = "Standard"
storage_account_replication_type = "LRS"
storage_account_allowed_ips = ["x.x.x.x"]

# =============================================================================
# Key Vault Configuration
# =============================================================================
key_vault_sku_name     = "standard"
key_vault_allowed_ips  = ["81.2.141.35","x.x.x.x"] # Management workstation / jump-box IP(s)

# =============================================================================
# DDoS Protection Configuration
# =============================================================================
enable_ddos_protection = false

# =============================================================================
# Monitoring Configuration
# Existing monitoring infrastructure - using for log ingestion estimates
# =============================================================================
log_analytics_workspace_sku = "PerGB2018"
application_insights_type   = "web"
dapr_config = {
  log_level = "info"
}


















