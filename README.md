# Introduction 
Terraform configuration to deploy Azure Automation PowerShell Runbooks.

All deployment code is saved in the `tf-deploy` directory. Terraform commands should be run from this directory. 

Environment specific input parameters can be found in the `environments` drectory. Each `environment` will have its own sub-directory (such as `Dev` or `Prod`). Within these environment directories there are 2 files, a `tfvars` file to specify the input parameters and a `backend.tf` file that contains the cofiguration of the backend state file.

The pipeline deployment file has multiple stages cofigued for each environment being deployed. Settings configured within the YAML Pipeline template ensure that the terraform commands use the correct `tfvars` and `backend.tf` files during the Plan and Deployment stages.

## tfvars
Generally, it is not advisable to check in `tfvars` into the git repository (by default tfvars are in the gitignore file). This is because of the potential for passwords and other sensitive information to be added as an input parameter and thereby checked into a git repo'. 

However, providing sensitive information like passwords should always be done using a secure solution such as lookups to Azure KeyVault. The Terraform data resource `azurerm_key_vault_secret` can read secrets direct from Azure KeyVault in a really easy and secure way. When sensitive inforation is only ever added in this type of way, saving the `tfvars` file into a private git repo does not introduce any additional risks.

Example KeyVault Secret data lookup block:

```js
data "azurerm_key_vault_secret" "sn_client_id" {
  name         = "sn_ClientId"
  key_vault_id = data.azurerm_key_vault.kv-sn-secrets.id
}
```

## Runbook Deployment
The Azure Automation Account runbooks are deployed using the terraform resource `azurerm_automation_runbook` with a `for_each` loop used to deploy one new Runbook for each PowerShell script found in the `./tf-deploy/psRunbooks` directory.

As part of the initial ceployment, the Runbook being deployed (`logExpiredKeys`) requires various credentials (namely to authenticate to ServiceNow when creating an alert/Ticket). These have also been defined using Terraform using the `azurerm_automation_credential` resource. 

These are not created on a for_each loop so each new credential will require its own, dedicated terraform resource block. The connection to ServiceNow requires two credentials to authenticate, a standard service account and also a Client ID (for connecting via the API). Once created, these credentials can be used by other runbook scripts if required.

```js
resource "azurerm_automation_credential" "sn_user_creds" {
  name                    = "sn_user_cred"
  resource_group_name     = var.resource_group_name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  username                = data.azurerm_key_vault_secret.sn_client_id.value
  password                = data.azurerm_key_vault_secret.sn_user_secret.value
  description             = "SN Service Account Credentials"
}

resource "azurerm_automation_credential" "sn_client_creds" {
  name                    = "sn_client_creds"
  resource_group_name     = var.resource_group_name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  username                = data.azurerm_key_vault_secret.sn_client_id.value
  password                = data.azurerm_key_vault_secret.sn_client_secret.value
  description             = "SN client ID Credentials"
```

You will notice in the code snippets above, that the username and password details are gathered using a data lookup. This data lookup will connect to the specified Azure keyVault and read the secrets defined in the data lookup. An example of a keyVault secret lookup can be seen above.


## `for_each` and script content
The terraform deployment uses a for_each loop to create a new Runbook for each PowerShell script that it finds in the `./psRunbooks` directory. This uses a terraform function called `fileset` which returns files from a specified path where they match a given pattern. Here, we use the powershell extension `.ps1`. So any scripts added into this directory that do not have the `.ps1` extension will not be included. 

We then need to read the content of the files, for which we use the `local_file` Terraform resource. This data lookup reads a local file and returns the content or Base64 encoded content. This data is then available through standard HCL interpolation syntax.

```js
data "local_file" "ps_runbooks" {
  for_each = local.ps_runbooks
  filename = "./psRunbooks/${each.value}"
}

```
We use a `for_each` loop to iterate over each of the powershell files returned from the `fileset` function. This then gives us an object that contains the contents of each powerShell script that can be accessed using standard terraform interpolation syntax:

```     data.local_file.ps_runbooks[0].content     ```




## automation account runbooks
Now that we have the details of the Runbooks/PowerShell scripts that need to be deployed, we can create the runbooks using the `azurerm_automation_runbook` resource. 

```js
resource "azurerm_automation_runbook" "ps_runbooks" {
  for_each = data.local_file.ps_runbooks

  name                    = trim(basename(each.value.filename), ".ps1")
  location                = data.azurerm_resource_group.kv-dev.location
  resource_group_name     = data.azurerm_resource_group.kv-dev.name
  automation_account_name = data.azurerm_automation_account.az_automation.name
  log_verbose             = var.log_verbose
  log_progress            = var.log_progress
  runbook_type            = "PowerShell"
  content                 = each.value.content
}
```

Here, we are again using a `for_each` loop to iterate over each of the returned objects from the `local_file` data lookup and create a new Runbook for each file returned. 

The returned data from the local_file lookup is an object that contains data such as the `filename` and the content of the PowerShell script. As we are using the `for_each` loop, we can access this data using `each.value.filename` & `each.value.content`.


## Data lookups & KeyVault Secrets


# runbook-test
