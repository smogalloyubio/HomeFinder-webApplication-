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
  use_cli                    = false

  environment   = "stack"            
  metadata_host = "localhost:4577"   

  subscription_id = "00000000-0000-0000-0000-000000000001"
  tenant_id       = "00000000-0000-0000-0000-000000000002"
  client_id       = "00000000-0000-0000-0000-000000000003"
  client_secret   = "fake-secret"    
}