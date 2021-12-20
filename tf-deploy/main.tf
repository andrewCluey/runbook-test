######################################
# Create Azure Automation Credentials
######################################


# Credential for ServiceNow service account
resource "azurerm_automation_credential" "sn_user_creds" {
  name                    = "sn_user_cred"
  resource_group_name     = var.resource_group_name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  username                = data.azurerm_key_vault_secret.sn_user_id.value
  password                = data.azurerm_key_vault_secret.sn_user_secret.value
  description             = "SN user Credentials"
}

# Credential for ServiceNow API Client ID
resource "azurerm_automation_credential" "sn_client_creds" {
  name                    = "sn_client_cred"
  resource_group_name     = var.resource_group_name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  username                = data.azurerm_key_vault_secret.sn_client_id.value
  password                = data.azurerm_key_vault_secret.sn_client_secret.value
  description             = "SN client Credentials"
}



###################################
# Create Azure Automation Runbooks
###################################

# Get all PowerShell files located in "./psRunbooks" directory
locals {
  ps_runbooks = fileset("./psRunbooks", "*.ps1")
}

# Read the data from the returned PowerShell files
data "local_file" "ps_runbooks" {
  for_each = local.ps_runbooks
  filename = "./psRunbooks/${each.value}"
}

# Deploy a Runbook for each PowerShell file found in directory
resource "azurerm_automation_runbook" "ps_runbooks" {
  for_each = data.local_file.ps_runbooks

  name                    = trim(basename(each.value.filename), ".ps1") # Runbook will have the same name as the script (minus the .ps1 extension)
  location                = data.azurerm_resource_group.automation_account_rg.location
  resource_group_name     = data.azurerm_resource_group.automation_account_rg.name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  log_verbose             = var.log_verbose
  log_progress            = var.log_progress
  runbook_type            = "PowerShell"
  content                 = each.value.content
}


# Create Schedules
resource "azurerm_automation_schedule" "every_friday" {
  name                    = "weekly_friday"
  resource_group_name     = var.resource_group_name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  frequency               = "Week"
  week_days               = ["Friday"]
  start_time              = "2021-12-18T01:00:00Z"
  description             = "Schedule to run weekly, every Friday."
}


