
variable "resource_group_name" {
  type        = string
  description = "The name of the Resource Group where the existing Automation Account exists (this is where the new Runbooks will be created too)."
}


variable "automation_account_name" {
  type        = string
  description = "The name of the Automation account where the new Runbook should be created."
}


variable "key_vault" {
  type = object({
    resource_group = string
    name          = string
  })
  description = "An input object specifying the details of the KeyVault (Name & Resource Group) where the ServiceNow credentials are stored."
}


variable "log_verbose" {
  type        = bool
  description = "Should verbose logging be enabled for the new Runbooks?"
  default     = true
}


variable "log_progress" {
  type        = bool
  description = "Should a record be written to the job history before and after each activity is run?"
  default     = true
}

variable "servicenow_uri" {
  type        = string
  description = "The uri of the ServiceNow API."
}