terraform {
  required_providers {
    namecheap = {
      source = "namecheap/namecheap"
      version = "2.1.0"
    }
    azurerm = {
      source = "hashicorp/azurerm"
      version = ">= 2.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_deleted_keys_on_destroy = true
      recover_soft_deleted_keys          = true
    }
  }
}

# Namecheap API credentials
provider "namecheap" {
  user_name   = data.azurerm_key_vault_secret.namecheap_user_name.value
  api_user    = data.azurerm_key_vault_secret.namecheap_api_user.value
  api_key     = data.azurerm_key_vault_secret.namecheap_api_key.value
  client_ip   = data.azurerm_key_vault_secret.namecheap_client_ip.value
  use_sandbox = false
}

data "azurerm_key_vault" "existing" {
  name                = "<<<VAULTNAME>>>"
  resource_group_name = "<<<VAULTGROUP>>>"  # Replace with your resource group name
}

data "azurerm_key_vault_secret" "namecheap_user_name" {
  name         = "namecheap-user-name"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "namecheap_client_ip" {
  name         = "namecheap-client-ip"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "namecheap_api_user" {
  name         = "namecheap-api-user"
  key_vault_id = data.azurerm_key_vault.existing.id
}

data "azurerm_key_vault_secret" "namecheap_api_key" {
  name         = "namecheap-api-key"
  key_vault_id = data.azurerm_key_vault.existing.id
}
