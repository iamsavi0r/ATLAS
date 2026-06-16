# ==============================================================================
# ATLAS Project - Level 2 (Providers Configuration)
# Domain: olympus.local | Author: savi0r
# ==============================================================================

terraform {
  required_version = ">= 1.0.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0" # Фиксируем мажорную версию для стабильности
    }
  }
}

provider "azurerm" {
  features {
    # Эти настройки гарантируют, что при удалении лабы (Destroy) 
    # Azure принудительно и чисто удалит диски и сетевые карты виртуалки
    virtual_machine {
      delete_os_disk_on_deletion     = true
      graceful_shutdown              = false
      skip_shutdown_and_force_delete = true
    }
  }
}
