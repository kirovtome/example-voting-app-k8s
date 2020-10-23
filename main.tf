resource "random_pet" "prefix" {}

provider "azurerm" {
  version = "~> 2.0"
  features {}
}

resource "azurerm_resource_group" "default" {
  name     = "${random_pet.prefix.id}-rg"
  location = "West US 2"

  tags = {
    environment = "dev"
  }
}

resource "azurerm_kubernetes_cluster" "default" {
  name                = "${random_pet.prefix.id}-aks"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  dns_prefix          = "${random_pet.prefix.id}-k8s"
  sku_tier            = var.sku_tier

  linux_profile {
      admin_username = "kadmin"
      
      ssh_key {
          key_data = file(var.ssh_public_key)
      }
  }

  default_node_pool {
    name            = "default"
    node_count      = var.agents_count
    vm_size         = var.agents_size
    os_disk_size_gb = 30
  }

  dynamic service_principal {
    for_each = var.appId != "" && var.password != "" ? ["service_principal"] : []
    content {
      client_id     = var.appId
      client_secret = var.password
    }
  }

  dynamic identity {
    for_each = var.appId == "" || var.password == "" ? ["identity"] : []
    content {
      type = "SystemAssigned"
    }
  }
 
  addon_profile {
    kube_dashboard {
      enabled = true
    }    

    dynamic oms_agent {
      for_each = var.enable_log_analytics_workspace ? ["log_analytics"] : []
      content {
        enabled                    = true
        log_analytics_workspace_id = azurerm_log_analytics_workspace.main[0].id
      }
    }
  }

  tags = {
    environment = "dev"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  count               = var.enable_log_analytics_workspace ? 1 : 0
  name                = "${random_pet.prefix.id}-workspace"
  location            = azurerm_resource_group.default.location
  resource_group_name = azurerm_resource_group.default.name
  sku                 = var.log_analytics_workspace_sku
  retention_in_days   = var.log_retention_in_days

}

resource "azurerm_log_analytics_solution" "main" {
  count                 = var.enable_log_analytics_workspace ? 1 : 0
  solution_name         = "ContainerInsights"
  location              = azurerm_resource_group.default.location
  resource_group_name   = azurerm_resource_group.default.name
  workspace_resource_id = azurerm_log_analytics_workspace.main[0].id
  workspace_name        = azurerm_log_analytics_workspace.main[0].name

  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/ContainerInsights"
  }
}
