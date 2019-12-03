$RGName = "LangskipServers"
$vNetRGName = "LangskipNetwork"
$vNetName = "vNet-Langskip-WE"
$subnetName = "Servers-Dynamic"
$Location = "West Europe"
$ResourceTags = @{"Event" = "ESPC2019"}
$VMName = "ls-web-1"
$VMSize = "Standard_A0"
$NICName = "$VMName-NIC"

# Define user name and blank password
$securePassword = ConvertTo-SecureString ' ' -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# NIC
$vNet = Get-AzVirtualNetwork -ResourceGroupName $vNetRGName `
                            -Name $vNetName


$NIC = New-AzNetworkInterface -Name $NICName `
                            -ResourceGroupName $RGName `
                            -Location $Location `
                            -SubnetId ( $VNet.Subnets | where { $_.Name -eq $subnetName } ).id

$VM = New-AzVMConfig -VMName $VMName `
                    -VMSize $VMSize
$VM = Set-AzVMOperatingSystem -VM $VM `
                            -Linux `
                            -ComputerName $VMName `
                            -DisablePasswordAuthentication `
                            -Credential $cred

$VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id
$VM = Set-AzVMSourceImage -VM $VM `
                        -PublisherName 'Canonical' `
                        -Offer 'UbuntuServer' `
                        -Skus "19.04" `
                        -Version latest

$sshPublicKey = Get-Content "$env:USERPROFILE\.ssh\langskip_id_rsa.pub"
Add-AzVMSshPublicKey -VM $VM -KeyData $sshPublicKey -Path "/home/azureuser/.ssh/authorized_keys"

New-AzVm `
    -ResourceGroupName $RGName `
    -VM $VM `
    -Location $Location `
    -Tag $ResourceTags

<#
mkdir html
echo $(hostname) > html/index.html
cd html/
python3 -m http.server 8080
#>