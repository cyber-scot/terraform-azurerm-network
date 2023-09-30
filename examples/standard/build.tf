module "rg" {
  source = "cyber-scot/rg/azurerm"

  name     = "rg-${var.short}-${var.loc}-${var.env}-01"
  location = local.location
  tags     = local.tags
}

module "network" {
  source = "cyber-scot/network/azurerm"

  rg_name  = module.rg.rg_name
  location = module.rg.rg_location
  tags     = module.rg.rg_tags

  vnet_name          = "vnet-${var.short}-${var.loc}-${var.env}-01"
  vnet_location      = module.rg.rg_location
  vnet_address_space = ["10.0.0.0/16"]

  subnets = {
    "sn1-${module.network.vnet_name}" = {
      prefix            = "10.0.0.0/24",
      service_endpoints = ["Microsoft.Storage"]
      delegation = [
        {
          type = "Microsoft.Web/serverFarms" # Provides lookup based action
        },
      ]
    }
    "sn2-${module.network.vnet_name}" = {
      prefix = "10.0.1.0/24",
    }
    "sn3-${module.network.vnet_name}" = {
      prefix = "10.0.2.0/24",
      delegation = [
        {
          type   = "Microsoft.Network/dnsResolvers" # Custom action declaration
          action = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
        },
      ]
    }
  }

  route_tables = {
    rt1 = {
      routes = {
        route1 = {
          address_prefix         = "0.0.0.0/0"
          next_hop_type          = "VirtualAppliance"
          next_hop_in_ip_address = "10.0.1.4"
        }
      }
    }
  }

  subnet_route_table_associations = {
    "sn1-${module.network.vnet_name}" = "rt1"
  }
}

