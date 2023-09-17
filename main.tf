resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  resource_group_name = var.rg_name
  location            = var.location
  address_space       = var.vnet_address_space
  dns_servers         = var.dns_servers
  tags                = var.tags
}

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = var.rg_name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = toset([each.value.prefix])
  service_endpoints    = toset(each.value.service_endpoints)

  dynamic "delegation" {
    for_each = each.value.delegation != null ? each.value.delegation : []
    content {
      name = delegation.value.type
      service_delegation {
        name    = delegation.value.type
        actions = lookup(var.subnet_delegations_actions, delegation.value.type, delegation.value.action)
      }
    }
  }
}

locals {
  subnets = {
    for subnet in azurerm_subnet.subnet :
    subnet.name => subnet.id
  }
}

resource "azurerm_subnet_network_security_group_association" "vnet" {
  for_each                  = var.nsg_ids != null ? var.nsg_ids : {}
  subnet_id                 = local.subnets[each.key]
  network_security_group_id = each.value
}
