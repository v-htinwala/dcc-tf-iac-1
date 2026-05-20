terraform {
  required_version = ">= 1.9.0"
  
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azapi = {
      source  = "azure/azapi"
      version = "~> 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = true
    }
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
  use_oidc                    = false # Set to true for CI/CD pipelines (GitHub Actions, Azure DevOps)
  subscription_id             = var.subscription_id
  storage_use_azuread         = true
}

provider "azapi" {
  subscription_id = var.subscription_id
  use_oidc        = false # Set to true for CI/CD pipelines (GitHub Actions, Azure DevOps)
}

