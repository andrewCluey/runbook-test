# Initialisation parameters 

# Backend Storage account details
resource_group_name  = "rg-vdc2-sp-devtst-terraformstate"                       # Resource Group where the Terraform remote state storage account lives.
storage_account_name = "terraformtfstatevdc"                          # The name of the Storage Account used for terraform remote state.
container_name       = "terraformstatefiles"                          # Name of the blob container used for the terraform remote state blobs
key                  = "AzureAutomationRunbooksDev.terraform.tfstate" # Name to assign to the remote state file (blob).