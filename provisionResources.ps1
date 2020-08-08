# TODO: set variables
$studentName = ""
$rgName = ""
$vmName = ""
$vmSize = ""
$vmImage = ""
$vmAdminUsername = ""
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG

# TODO: provision VM

# TODO: capture the VM systemAssignedIdentity

# TODO: open vm port 443

# provision KV

az keyvault create -n $kvName --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file
