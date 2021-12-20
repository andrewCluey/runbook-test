# Weekly schedule for "LogExpiredKeys" script
resource "azurerm_automation_job_schedule" "logexpiredkeys_job" {
  resource_group_name     = data.azurerm_resource_group.automation_account_rg.name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  schedule_name           = azurerm_automation_schedule.every_friday.name
  runbook_name            = azurerm_automation_runbook.ps_runbooks["logExpiredKeys.ps1"].name

  parameters = {
    servicenowuri   = var.servicenow_uri
    alertbeforedays = 30
    servicenowuser  = data.azurerm_key_vault_secret.sn_user_id.value
  }
}