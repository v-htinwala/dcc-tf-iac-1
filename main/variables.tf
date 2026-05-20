# General Variables
variable "subscription_id" {
  description = "Azure subscription ID"
  type        = string
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "ukwest"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}

# Network Variables
variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
  default     = ["172.29.110.0/24"]
}

variable "appgw_subnet_prefix" {
  description = "Address prefix for Application Gateway subnet"
  type        = string
  default     = "172.29.110.0/26"
}

variable "appservice_integration_subnet_prefix" {
  description = "Address prefix for App Service integration subnet"
  type        = string
  default     = "172.29.110.64/27"
}

variable "sql_mi_subnet_prefix" {
  description = "Address prefix for SQL Managed Instance subnet (minimum /27)"
  type        = string
  default     = "172.29.110.96/27"
}

variable "private_endpoint_subnet_prefix" {
  description = "Address prefix for private endpoint subnet"
  type        = string
  default     = "172.29.110.128/28"
}

# Application Gateway Variables
variable "appgw_sku_name" {
  description = "SKU name for Application Gateway (WAF_v2 recommended)"
  type        = string
  default     = "WAF_v2"
}

variable "appgw_sku_tier" {
  description = "SKU tier for Application Gateway (WAF_v2 recommended)"
  type        = string
  default     = "WAF_v2"
}

variable "appgw_capacity" {
  description = "Capacity for Application Gateway"
  type        = number
  default     = 2
}

variable "appgw_private_ip_address" {
  description = "Static private IP address for the Application Gateway internal frontend"
  type        = string
  default     = "172.29.110.10"
}

variable "appgw_waf_mode" {
  description = "WAF firewall mode (Detection = log only, Prevention = actively block)"
  type        = string
  default     = "Prevention"

  validation {
    condition     = contains(["Detection", "Prevention"], var.appgw_waf_mode)
    error_message = "appgw_waf_mode must be either 'Detection' or 'Prevention'."
  }
}

variable "appgw_waf_rule_set_version" {
  description = "OWASP rule set version for the WAF (3.2 is the latest supported)"
  type        = string
  default     = "3.2"
}

# App Service Variables
variable "app_service_plan_sku_name" {
  description = "SKU name for App Service Plan (Standard minimum for VNet integration)"
  type        = string
  default     = "S1"
}

variable "app_service_plan_instance_count" {
  description = "Number of App Service Plan instances (1 sufficient for PoC in UK West - no AZs)"
  type        = number
  default     = 1
}

# SQL Managed Instance Variables
variable "sql_managed_instance_admin_username" {
  description = "Administrator username for SQL Managed Instance"
  type        = string
  sensitive   = true
}

variable "sql_managed_instance_admin_password" {
  description = "Administrator password for SQL Managed Instance"
  type        = string
  sensitive   = true
}

variable "sql_managed_instance_sku_name" {
  description = "SKU name for SQL Managed Instance (GP_Gen5 = General Purpose)"
  type        = string
  default     = "GP_Gen5"
}

variable "sql_managed_instance_vcores" {
  description = "Number of vCores for SQL Managed Instance (minimum 4)"
  type        = number
  default     = 4
}

variable "sql_managed_instance_storage_size_gb" {
  description = "Storage size in GB for SQL Managed Instance"
  type        = number
  default     = 32
}

variable "sql_managed_instance_license_type" {
  description = "License type for SQL Managed Instance (LicenseIncluded or BasePrice for BYOL)"
  type        = string
  default     = "LicenseIncluded"
}

# Storage Account Variables
variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "LRS"
}

# Key Vault Variables
variable "key_vault_sku_name" {
  description = "SKU name for Key Vault"
  type        = string
  default     = "standard"
}

# DDoS Protection Variables
variable "enable_ddos_protection" {
  description = "Enable DDoS protection plan"
  type        = bool
  default     = true
}

variable "firewall_ip" {
  description = "IP address of the hub firewall (next hop for default route)"
  type        = string
  default     = "172.29.7.132"
}

# Monitoring Variables
variable "log_analytics_workspace_sku" {
  description = "SKU for Log Analytics Workspace"
  type        = string
  default     = "PerGB2018"
}

variable "application_insights_type" {
  description = "Application type for Application Insights"
  type        = string
  default     = "web"
}

# Key Vault Network ACL Variables
variable "key_vault_allowed_ips" {
  description = "List of IP addresses permitted through the Key Vault network ACL (e.g. management workstation IPs)"
  type        = list(string)
  default     = []
}

# Storage Account Network ACL Variables
variable "storage_account_allowed_ips" {
  description = "List of IP addresses permitted through the Storage Account network ACL (e.g. management workstation IPs)"
  type        = list(string)
  default     = []
}

#dapr variables to ignore null entries
variable "dapr_config" {
  type = object({
    log_level = string
  })
  default = {
    log_level = "info"
  }
}













