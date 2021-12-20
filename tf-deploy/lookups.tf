##########################################
# Lookup data for existing Azure Resources
##########################################

# Details of the Resource Group where the Automation Account resides
data "azurerm_resource_group" "automation_account_rg" {
  name = var.resource_group_name
}

# Details of the existing Azure Automation Account
data "azurerm_automation_account" "az_automation" {
  name                = var.automation_account_name
  resource_group_name = data.azurerm_resource_group.automation_account_rg.name
}

# Details of the KeyVault that holds ServiceNow Credentials & Secrets
data "azurerm_key_vault" "kv-sn-secrets" {
  name                = var.key_vault.name
  resource_group_name = var.key_vault.resource_group
}



#########################
# Lookup KeyVault Secrets
#########################

# Lookup ServiceNow Service Account ID from Key Vault
data "azurerm_key_vault_secret" "sn_user_id" {
  name         = "snSvcUser"
  key_vault_id = data.azurerm_key_vault.kv-sn-secrets.id
}
# Lookup ServiceNow Service Account Password from Key Vault
data "azurerm_key_vault_secret" "sn_user_secret" {
  name         = "snSvcPass"
  key_vault_id = data.azurerm_key_vault.kv-sn-secrets.id
}



# Lookup ServiceNow client ID from Key Vault
data "azurerm_key_vault_secret" "sn_client_id" {
  name         = "snClientId"
  key_vault_id = data.azurerm_key_vault.kv-sn-secrets.id
}
# Lookup ServiceNow client ID Password from Key Vault
data "azurerm_key_vault_secret" "sn_client_secret" {
  name         = "snClientSecret"
  key_vault_id = data.azurerm_key_vault.kv-sn-secrets.id
}



