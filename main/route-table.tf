resource "azurerm_route_table" "main" {
  name                          = "rt-${var.environment}-${local.resource_suffix}"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  bgp_route_propagation_enabled = true

  # Default route to firewall
  route {
    name                   = "default"
    address_prefix         = "0.0.0.0/0"
    next_hop_type          = "VirtualAppliance"
    next_hop_in_ip_address = var.firewall_ip
  }

  # SQL MI subnet route (required)
  route {
    name           = "sql-mi-vnetlocal"
    address_prefix = var.sql_mi_subnet_prefix
    next_hop_type  = "VnetLocal"
  }

  # Azure service routes (required for SQL MI)
  route {
    name           = "aad"
    address_prefix = "AzureActiveDirectory"
    next_hop_type  = "Internet"
  }

  route {
    name           = "azurecloud-uksouth"
    address_prefix = "AzureCloud.uksouth"
    next_hop_type  = "Internet"
  }

  route {
    name           = "azurecloud-ukwest"
    address_prefix = "AzureCloud.ukwest"
    next_hop_type  = "Internet"
  }

  route {
    name           = "oneds"
    address_prefix = "OneDsCollector"
    next_hop_type  = "Internet"
  }

  route {
    name           = "storage-uksouth"
    address_prefix = "Storage.uksouth"
    next_hop_type  = "Internet"
  }

  route {
    name           = "storage-ukwest"
    address_prefix = "Storage.ukwest"
    next_hop_type  = "Internet"
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

resource "azurerm_subnet_route_table_association" "appservice" {
  subnet_id      = module.vnet.subnets["snet-appservice-integration"].resource_id
  route_table_id = azurerm_route_table.main.id
}

resource "azurerm_subnet_route_table_association" "sql_mi" {
  subnet_id      = module.vnet.subnets["snet-sql-managed-instance"].resource_id
  route_table_id = azurerm_route_table.main.id
}

