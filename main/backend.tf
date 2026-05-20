terraform {
  backend "azurerm" {
    resource_group_name  = "DCC-RG-TFSTATE"
    storage_account_name = "dccterraform"
    container_name       = "tfstate"
    key                  = "poc.terraform.tfstate"
  }
}