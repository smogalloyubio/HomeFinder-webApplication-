terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  #skip_provider_registration = true
  subscription_id = "a2b28c85-1948-4263-90ca-bade2bac4df4"
  tenant_id       = "30fe8ff1-adc6-444d-ba94-1238894df42c"

}