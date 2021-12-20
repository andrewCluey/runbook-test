# Requires the following PowerShell modules installing within the automation account
   # - ServiceNow (Runtime Ps5.1)
   # - Az.Accounts (>= v2.6.0; Runtime Ps5.1) 
   # - Az.KeyVault (>= v3.6.0 Ps5.1)

# Automation Account identity requires the following roles assigning
   # - Key Vault reader assigned at the Subscription (script searhces inside ALL keyvaults for expiring keys)

param
(
    [Parameter (Mandatory = $true)]
    [string]$servicenowuri,

    [Parameter (Mandatory = $false)]
    [int] $alertbeforedays = 30,

    [Parameter (Mandatory = $false)]
    [string] $servicenowuser = "svc.AzAutomation"

)


$user = $servicenowUser
$allVaults = Get-AzKeyVault
$vaultNames = $allVaults.VaultName

# Suppress deprecated feature warning
Set-Item Env:\SuppressAzurePowerShellBreakingChangeWarnings "true"
# Authenticate to Azure using MSI
Disable-AzContextAutosave -Scope Process
# Connect to Azure with system-assigned managed identity
$azureContext = (Connect-AzAccount -Identity).context
# set and store context
$azureContext = Set-AzContext -SubscriptionName $azureContext.Subscription -DefaultProfile $AzureContext


###########
# Functions
###########
Function New-KeyVaultObject
{
    param
    (
        [string]$Id,
        [string]$Name,
        [string]$Version,
        [System.Nullable[DateTime]]$Expires
    )

    $server = New-Object -TypeName PSObject
    $server | Add-Member -MemberType NoteProperty -Name Id -Value $Id
    $server | Add-Member -MemberType NoteProperty -Name Name -Value $Name
    $server | Add-Member -MemberType NoteProperty -Name Version -Value $Version
    $server | Add-Member -MemberType NoteProperty -Name Expires -Value $Expires
    
    return $server
}

function Get-AzureKeyVaultObjectKeys
{
  param
  (
   [string]$VaultName
  )

  $vaultObjects = [System.Collections.ArrayList]@()
  $allKeys = Get-AzKeyVaultKey -VaultName $VaultName
  foreach ($key in $allKeys) {
      $vaultObject = New-KeyVaultObject -Id $key.Id -Name $key.Name -Version $key.Version -Expires $key.Expires
      $vaultObjects.Add($vaultObject)
  }
  
  return $vaultObjects
}




# Create ServiceNow Session
# Gather Credentials from Key Vault
$userCred = Get-AutomationPSCredential -Name "sn_user_cred"
#$clientCred = Get-AutomationPSCredential -Name "sn_client_cred"

$params = @{
    Url = "dev110690.service-now.com"
    Credential = $userCred
    #ClientCredential = $clientCred
}
New-ServiceNowSession @params

############################################################################################
# Find Expiring Keys and Create ServiceNow Incident for each (if it doesn't already exist).
############################################################################################

<# ServiceNow Incident Status codes
New             1 
In Progress     2 
On Hold         3 
Resolved        6 
Closed          7 
Canceled        8 
#>

foreach ($vaultName in $vaultNames) {
    # Add keys found into a new PS
    $vaultObjectKeys = Get-AzureKeyVaultObjectKeys -VaultName $vaultName
    $allKeyVaultObjects = [System.Collections.ArrayList]@()
     # Conditional to bypass if no keys found in KeyVault.
     if ($vaultObjectKeys) {
        $allKeyVaultObjects.AddRange($vaultObjectKeys)
        $today = (Get-Date).Date
        $expiredKeyVaultObjects = [System.Collections.ArrayList]@()
        
        foreach($vaultObject in $allKeyVaultObjects){
            if ($vaultObject.Expires -and $vaultObject.Expires.AddDays(-$alertBeforeDays).Date -lt $today) {
                $keyId = $vaultObject.Id
                $keyName = $vaultObject.name
                $keyExpiry = $vaultObject.expires

                # Create filter to find matching incident tickets
                $filter = @('state', '-eq', '1'),
                'and',
                @('short_description','-eq', "Key $keyId is expiring"),
                'group',
                @('state', '-eq', '2'),
                'and',
                @('short_description','-eq', "Key $keyId is expiring"),
                'group',
                @('state', '-eq', '3'),
                'and',
                @('short_description','-eq', "Key $keyId is expiring")
                
                $ticket = Get-ServiceNowRecord -Table incident -Filter $filter
                $ticketRef = $ticket.number
                if (-not $ticket) {          # Create new ticket for the expiring key IF no Ticket is found that matches the filter.
                    $expiredKeyVaultObjects.Add($vaultObject) | Out-Null
                    Write-Output "Key with ID" $vaultObject.Id "is Expiring"
                    Write-output "Creating new Incident"
                    $newTicket = New-ServiceNowIncident -Caller $user `
                        -ShortDescription "Key $keyId is expiring" `
                        -Description "The following Key is due to expire within the next $alertBeforeDays days:`n`t
                            $keyName`r`n
                        With ID:`n`t
                            $keyId`r`n
                        Expires on:`n`t
                            $keyExpiry" `
                        -AssignmentGroup "Incident Management" -Comment "Inline comment" -Category "Software" `
                        -Subcategory "Internal Application"
            
                    $newTicket
                } else {
                    write-host "An incident for the key with id $keyId has already been created. $ticketRef"
                }
            }
        }
    }
}



