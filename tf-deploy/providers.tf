terraform {
  backend "azurerm" {}
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "= 2.87.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}
