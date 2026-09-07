resource "azurerm_resource_group" "project1-rg" {
  name     = "project1-rg" # string values need quotes in HCL
  location = "eastus"
}

resource "azurerm_virtual_network" "project1-vn" {
  name                = "project1-vn"
  address_space       = ["10.1.0.0/16"] # a list of CIDR blocks, not a bare number
  location            = "eastus"
  resource_group_name = azurerm_resource_group.project1-rg.name
  # ^ references the RG resource above (type.local_name.attribute) instead of
  # hardcoding the string "project1-rg" again. This tells Terraform "create the
  # RG first, then this VNet" automatically (implicit dependency).
}

resource "azurerm_subnet" "project1-s" {
  name                 = "project1-s"
  resource_group_name  = azurerm_resource_group.project1-rg.name
  virtual_network_name = azurerm_virtual_network.project1-vn.name
  address_prefixes     = ["10.1.1.0/24"] # a slice carved out of the VNet's 10.0.0.0/16 range
}

resource "azurerm_kubernetes_cluster" "project1-kc" {
  name                = "project1-kc"
  location            = "eastus"
  resource_group_name = azurerm_resource_group.project1-rg.name  # reference the RG
  dns_prefix          = "project1-aks"  # a unique-ish string, becomes part of the cluster's API server hostname

  default_node_pool {
    name           = "project1np"
    node_count     = 1
    vm_size        = "Standard_D2as_v7"
    vnet_subnet_id = azurerm_subnet.project1-s.id  # reference the subnet
  }

  identity {
    type = "SystemAssigned"  # "SystemAssigned"
  }

  network_profile {
    network_plugin = "kubenet"  # "kubenet", matching our earlier decision
  }
}
