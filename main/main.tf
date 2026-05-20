# Main Terraform Configuration for Azure Application Architecture

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location

  tags = var.tags
}

# Generate random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  resource_suffix = random_string.suffix.result
  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
  
  # VNet module output compatibility
  vnet_id = module.vnet.resource_id
  vnet_name = module.vnet.resource.name
  vnet_subnets = {
    "snet-appgw"                    = module.vnet.subnets["snet-appgw"].resource_id
    "snet-appservice-integration"   = module.vnet.subnets["snet-appservice-integration"].resource_id
    "snet-sql-mi"                   = module.vnet.subnets["snet-sql-managed-instance"].resource_id
    "snet-private-endpoints"        = module.vnet.subnets["snet-private-endpoints"].resource_id
  }
}
