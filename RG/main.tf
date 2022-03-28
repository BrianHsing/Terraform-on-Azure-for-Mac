terraform {

  required_version = ">=0.12"
  
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}

  subscription_id   = "15460747-219f-4ef3-8606-651f1fa0d4bc"
  tenant_id         = "7d8e52e5-a6ad-401f-8264-ca171a7e0811"
  client_id         = "fb3c37a9-95c7-4fd5-a8fd-f69fd2c39c7d"
  client_secret     = "MyGp-3I~Ht2V0rxQl4MBwL8~vjvWtaaI.M"
}

resource "azurerm_resource_group" "rg" {
  name      = "terraform-rg"
  location  = "eastasia"
}