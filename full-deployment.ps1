#!/snap/bin/pwsh

# --- start ---

# variables

$rgName = "linux-ts-rg"
$vmName = "broken-linux-vm"
$vmSize = "Standard_B2s"
# $vmSize = "Standard_B1ls" # bad broken size waaay too small; won't even make it through the first runCommand
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn")"
$vmAdminUsername = "student"
$kvName = "lcts-$(Get-Random -Maximum 100000)-kv-$(Get-Random -Maximum 100000)"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

Write-Output "Checking Azure subscription for resource groups matching: $rgName"

foreach ($group in $(az group list | ConvertFrom-Json)) {
        if($group.name -eq "$rgName") {
                Write-Output "FOUND $rgName"
		Write-Output "DELETING $rgName this will take a couple of minutes..."
		az group delete -n $rgName -y
        }
}

# set az location default

Write-Output "configuring AZ CLI location default to eastus"

az configure --default location=eastus

# RG: provision

Write-Output "creating new Resource Group: $rgName"

az group create -n "$rgName" | Set-Content outputs/resourceGroup.json

# set az rg default

Write-Output "configuring AZ CLI resource group default to $rgName"

az configure --default group=$rgName

# VM: provision

Write-Output "creating new Virtual Machine: $vmName"

az vm create -n "$vmName" --size "$vmSize" --image "$vmImage" --admin-username "$vmAdminUsername" --admin-password "LaunchCode-@zure1" --authentication-type "password" --assign-identity | Set-Content outputs/virtualMachine.json

# set az vm default

Write-Output "configuring AZ CLI VM default to $vmName"

az configure --default vm=$vmName

# KV: provision

Write-Output "creating new Key Vault: $kvName"

az keyvault create -n "$kvName" --enable-soft-delete "false" --enabled-for-deployment "true" | Set-Content outputs/keyVault.json

# KV: set secret

Write-Output "creating new KV secret in $kvName"

az keyvault secret set --vault-name "$kvName" --description "connection string" --name "$kvSecretName" --value "$kvSecretValue"

# az keyvault secret set --vault-name "$kvName" --description "DB connection string" --file connectionString.json

# VM open NSGs

# Write-Output "opening $vmName port 443"

# az vm open-port --port 443

# VM: grant access to KV

# Write-Output "granting VM 'get' access to KV secrets"

$vm = Get-Content outputs/virtualMachine.json | ConvertFrom-Json

# az keyvault set-policy --name "$kvName" --object-id $vm.identity.systemAssignedIdentity --secret-permissions list get

# VM setup-and-deploy script

# az vm run-command invoke --command-id RunShellScript --scripts @1configure-vm.sh @2configure-ssl.sh @deliver-deploy.sh

Write-Output "sending vm-config/1configure-vm.sh to $vmName"

az vm run-command invoke --command-id RunShellScript --scripts @vm-config/1configure-vm.sh | Set-Content outputs/configureVm.json

Write-Output "results of RunCommand 1configure-vm found in outputs/configureVm.json"

Write-Output "sending vm-config/2configure-ssl.sh to $vmName"

az vm run-command invoke --command-id RunShellScript --scripts @vm-config/2configure-ssl.sh | Set-Content outputs/configureSsl.json

Write-Output "results of RunCommand 2configure-ssl.sh in outputs/configureSsl.json"

Write-Output "sending deliver-deploy.sh to $vmName"

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh | Set-Content outputs/deliverDeploy.json

Write-Output "results of RunCommand deliver-deploy found in outputs/deliverDeploy.json"

# finished print out IP address

Write-Output "VM available at $($vm.publicIpAddress)"

az vm stop --only-show-errors

# --- end ---

# access deployed app
