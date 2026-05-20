# DDoS Protection Plan
resource "azurerm_network_ddos_protection_plan" "main" {
  count               = var.enable_ddos_protection ? 1 : 0
  name                = "ddos-protection-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = local.common_tags
}

# Virtual Network Module using Azure Verified Module
module "vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.17.1"

  name          = "vnet-${var.environment}-${local.resource_suffix}"
  parent_id     = azurerm_resource_group.main.id
  location      = azurerm_resource_group.main.location
  address_space = var.vnet_address_space

  subnets = {
    snet-appgw = {
      name             = "snet-appgw"
      address_prefixes = [var.appgw_subnet_prefix]
    }
    snet-appservice-integration = {
      name             = "snet-appservice-integration"
      address_prefixes = [var.appservice_integration_subnet_prefix]
      delegations = [{
        name = "Microsoft.Web/serverFarms"
        service_delegation = {
          name = "Microsoft.Web/serverFarms"
        }
      }]
    }
    snet-sql-managed-instance = {
      name             = "snet-sql-mi"
      address_prefixes = [var.sql_mi_subnet_prefix]
      delegations = [{
        name = "Microsoft.Sql/managedInstances"
        service_delegation = {
          name = "Microsoft.Sql/managedInstances"
        }
      }]
    }
    snet-private-endpoints = {
      name             = "snet-private-endpoints"
      address_prefixes = [var.private_endpoint_subnet_prefix]
    }
  }

  tags = local.common_tags

  depends_on = [azurerm_resource_group.main]
}

# data "azurerm_virtual_network" "hub" {
# name                = var.hub_vnet_name
# resource_group_name = var.hub_vnet_resource_group_name
# }

# resource "azurerm_virtual_network_peering" "spoke_to_hub" {
#  name                      = "peer-${var.hub_vnet_name}-to-hub"
#  resource_group_name       = azurerm_resource_group.main.name
#  virtual_network_name      = module.vnet.name
#  remote_virtual_network_id = data.azurerm_virtual_network.hub.id

#  allow_virtual_network_access = true
#  allow_forwarded_traffic      = true
#  allow_gateway_transit        = false
#  use_remote_gateways          = true

# depends_on = [module.vnet]
# }

#resource "azurerm_virtual_network_peering" "hub_to_spoke" {
#  name                      = "peer-hub-to-${var.spoke_vnet_name}"
# resource_group_name       = data.azurerm_virtual_network.hub.resource_group_name
# virtual_network_name      = data.azurerm_virtual_network.hub.name
# remote_virtual_network_id = module.vnet.resource_id

# allow_virtual_network_access = true
#  allow_forwarded_traffic      = true
#  allow_gateway_transit        = true
#  use_remote_gateways          = false
# }


# Network Security Group for Application Gateway Subnet
resource "azurerm_network_security_group" "appgw" {
  name                = "nsg-appgw-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-Internet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-GatewayManager"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "65200-65535"
    source_address_prefix      = "GatewayManager"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "Allow-AzureLoadBalancer"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  tags = local.common_tags
}

# Network Security Group for App Service Integration Subnet
resource "azurerm_network_security_group" "appservice_integration" {
  name                = "nsg-appservice-integration-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-AppGateway-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443"]
    source_address_prefix      = var.appgw_subnet_prefix
    destination_address_prefix = "*"
  }
 
  tags = local.common_tags
}

# Network Security Group for Private Endpoint Subnet
resource "azurerm_network_security_group" "private_endpoints" {
  name                = "nsg-private-endpoints-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                       = "Allow-VNet-Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "VirtualNetwork"
  }

  tags = local.common_tags
}

# Network Security Group for SQL Managed Instance Subnet
resource "azurerm_network_security_group" "sql_mi" {
  name                = "nsg-sql-mi-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow management inbound traffic
  security_rule {
    name                       = "allow_management_inbound"
    priority                   = 106
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["9000", "9003", "1438", "1440", "1452"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_misubnet_inbound"
    priority                   = 200
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = var.sql_mi_subnet_prefix
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_health_probe_inbound"
    priority                   = 300
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "AzureLoadBalancer"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_tds_inbound"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "1433"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_redirect_inbound"
    priority                   = 1100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "11000-11999"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny_all_inbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Outbound rules
  security_rule {
    name                       = "allow_management_outbound"
    priority                   = 102
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["80", "443", "12000"]
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow_misubnet_outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = var.sql_mi_subnet_prefix
  }

  tags = local.common_tags
}

# NSG Association - Application Gateway Subnet
resource "azurerm_subnet_network_security_group_association" "appgw" {
  subnet_id                 = local.vnet_subnets["snet-appgw"]
  network_security_group_id = azurerm_network_security_group.appgw.id
}

# NSG Association - App Service Integration Subnet
resource "azurerm_subnet_network_security_group_association" "appservice_integration" {
  subnet_id                 = local.vnet_subnets["snet-appservice-integration"]
  network_security_group_id = azurerm_network_security_group.appservice_integration.id
}

# NSG Association - SQL Managed Instance Subnet
resource "azurerm_subnet_network_security_group_association" "sql_mi" {
  subnet_id                 = local.vnet_subnets["snet-sql-mi"]
  network_security_group_id = azurerm_network_security_group.sql_mi.id
}

# NSG Association - Private Endpoint Subnet
resource "azurerm_subnet_network_security_group_association" "private_endpoints" {
  subnet_id                 = local.vnet_subnets["snet-private-endpoints"]
  network_security_group_id = azurerm_network_security_group.private_endpoints.id
}













