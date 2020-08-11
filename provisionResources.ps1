# TODO: set variables
$studentName = "will"
$rgName = "$studentName-9-lc-rg"
$vmName = "$studentName-9-lc-rg"
$vmSize = "Standard_B2s"
$vmImage = "Canonical:UbuntuServer:18.04-LTS:latest"
$vmAdminUsername = "student"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG
az group create -n $rgName
az configure --default group=$rgName

# TODO: provision VM
az vm create -n $vmName --size $vmSize --image $vmImage --admin-username $vmAdminUsername --admin-password "LaunchCode-@zure1" --authentication-type "password" --assign-identity | Set-Content vm.json

# TODO: capture the VM systemAssignedIdentity
az configure --default vm=$vmName
$vm = Get-Content vm.json | ConvertFrom-Json
$vmsystemAssignedIdentity = $vm.identity.systemAssignedIdentity

# TODO: open vm port 443
az vm open-port --port 443

# provision KV
az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)
az keyvault secret set --vault-name $kvName --description "db connection string" --name $kvSecretName --value $kvSecretValue

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)
az keyvault set-policy --name $kvName --object-id $vmsystemAssignedIdentity --secret-permissions list get

cd C:\Users\Will\Desktop\studio9\powershell-az-cli-scripting-deployment

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

# this is supposed to set the ServerOrigin to the newly created VM IP

cd C:\Users\Will\Desktop\studio9-coding-events
git checkout studio-9
$appSettings = Get-Content CodingEventsAPI\appsettings.json | ConvertFrom-Json
$appSettings.ServerOrigin = $vm.publicipaddress
$appSettings | ConvertTo-Json | Set-Content CodingEventsAPI\appsettings.json
git add .
git commit -m "set ServerOrigin"
git push
cd C:\Users\Will\Desktop\studio9\powershell-az-cli-scripting-deployment


az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file
echo $vm.publicipaddress

