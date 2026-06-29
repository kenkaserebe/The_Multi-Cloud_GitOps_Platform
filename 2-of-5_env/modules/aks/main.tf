# The_Multi-Cloud_GitOps_Platform/2-of-5_env/modules/aks/main.tf

# Virtual network
resource "azurerm_virtual_network" "this" {
  name                  = "${var.az_cluster_name}-vnet"
  location              = var.az_location
  resource_group_name   = var.az_resource_group_name
  address_space         = var.az_vnet_address_space
  tags                  = var.az_tags
}

# Subnet for AKS nodes
resource "azurerm_subnet" "aks" {
  name                  = "${var.az_cluster_name}-subnet"
  resource_group_name   = var.az_resource_group_name
  virtual_network_name  = azurerm_virtual_network.this.name
  address_prefixes      = var.az_subnet_address_prefixes
}

# AKS Cluster
resource "azurerm_kubernetes_cluster" "this" {
  name                  = var.az_cluster_name
  location              = var.az_location
  resource_group_name   = var.az_resource_group_name
  dns_prefix            = var.az_dns_prefix != "" ? var.az_dns_prefix : var.az_cluster_name
  kubernetes_version    = var.az_kubernetes_version

  # Use system-assigned managed identity
  identity {
    type = "SystemAssigned"
  }

  default_node_pool {
    name            = "default"
    node_count      = var.az_node_count
    vm_size         = var.az_node_vm_size
    vnet_subnet_id  = azurerm_subnet.aks.id

    # Enable auto-scaling if desired
    auto_scaling_enabled    = var.az_enable_auto_scaling
    min_count               = var.az_enable_auto_scaling ? var.az_min_node_count: null
    max_count               = var.az_enable_auto_scaling ? var.az_max_node_count: null

    upgrade_settings {
        max_surge = "10%"
    }
  }

  network_profile {
    network_plugin  = "kubenet"
    network_policy  = "calico"
    service_cidr    = "10.0.0.0/16"
    dns_service_ip  = "10.0.0.10"
  }

  # Enable RBAC
  role_based_access_control_enabled = true

  tags        = var.az_tags

  depends_on  = [
    azurerm_subnet.aks
  ]
}






