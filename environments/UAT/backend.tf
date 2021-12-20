# Initialisation parameters 

# Backend Storage account details
resource_group_name  = ""                                             # Resource Group where the Terraform remote state storage account lives.
storage_account_name = ""                                             # The name of the Storage Account used for terraform remote state.
container_name       = ""                                             # Name of the blob container used for the terraform remote state blobs
key                  = "AzureAutomationRunbooksUAT.terraform.tfstate" # Name to assign to the remote state file (blob).