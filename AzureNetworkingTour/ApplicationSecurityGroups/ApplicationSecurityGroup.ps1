<#
ApplicationSecurityGroup.ps1



#>

$location = "westcentralus"
$ResourceGroupName = "RGApplicationSecurityGroup"
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location

$webAsg = New-AzureRmApplicationSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Name WebServers `
  -Location $location

$appAsg = New-AzureRmApplicationSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Name AppServers `
  -Location $location

$databaseAsg = New-AzureRmApplicationSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Name DatabaseServers `
  -Location $location

  $webRule = New-AzureRmNetworkSecurityRuleConfig `
  -Name "WebRule" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 200 `
  -SourceAddressPrefix Internet `
  -SourcePortRange * `
  -DestinationApplicationSecurityGroupId $webAsg.id `
  -DestinationPortRange 80  

$appRule = New-AzureRmNetworkSecurityRuleConfig `
  -Name "AppRule" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 300 `
  -SourceApplicationSecurityGroupId $webAsg.id `
  -SourcePortRange * `
  -DestinationApplicationSecurityGroupId $appAsg.id `
  -DestinationPortRange 443 

$databaseRule = New-AzureRmNetworkSecurityRuleConfig `
  -Name "DatabaseRule" `
  -Access Allow `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 400 `
  -SourceApplicationSecurityGroupId $appAsg.id `
  -SourcePortRange * `
  -DestinationApplicationSecurityGroupId $databaseAsg.id `
  -DestinationPortRange 1336

  $nsg = New-AzureRmNetworkSecurityGroup `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Name myNsg `
  -SecurityRules $WebRule,$AppRule,$DatabaseRule

  $subnet = New-AzureRmVirtualNetworkSubnetConfig `
  -AddressPrefix 10.0.0.0/24 `
  -Name mySubnet `
  -NetworkSecurityGroup $nsg

  $vNet = New-AzureRmVirtualNetwork `
  -Name myVnet `
  -AddressPrefix '10.0.0.0/16' `
  -Subnet $subnet `
  -ResourceGroupName $ResourceGroupName `
  -Location $location

  $nic1 = New-AzureRmNetworkInterface `
  -Name myNic1 `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Subnet $vNet.Subnets[0] `
  -NetworkSecurityGroup $nsg `
  -ApplicationSecurityGroup $webAsg,$appAsg

$nic2 = New-AzureRmNetworkInterface `
  -Name myNic2 `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Subnet $vNet.Subnets[0] `
  -NetworkSecurityGroup $nsg `
  -ApplicationSecurityGroup $appAsg

$nic3 = New-AzureRmNetworkInterface `
  -Name myNic3 `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -Subnet $vNet.Subnets[0] `
  -NetworkSecurityGroup $nsg `
  -ApplicationSecurityGroup $databaseAsg

  # Create user object
$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# Create the web server virtual machine configuration and virtual machine.
$webVmConfig = New-AzureRmVMConfig `
  -VMName myWebVm `
  -VMSize Standard_DS1_V2 | `
Set-AzureRmVMOperatingSystem -Windows `
  -ComputerName myWebVm `
  -Credential $cred | `
Set-AzureRmVMSourceImage `
  -PublisherName MicrosoftWindowsServer `
  -Offer WindowsServer `
  -Skus 2016-Datacenter `
  -Version latest | `
Add-AzureRmVMNetworkInterface `
  -Id $nic1.Id
New-AzureRmVM `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -VM $webVmConfig

# Create the app server virtual machine configuration and virtual machine.
$appVmConfig = New-AzureRmVMConfig `
  -VMName myAppVm `
  -VMSize Standard_DS1_V2 | `
Set-AzureRmVMOperatingSystem -Windows `
  -ComputerName myAppVm `
  -Credential $cred | `
Set-AzureRmVMSourceImage `
  -PublisherName MicrosoftWindowsServer `
  -Offer WindowsServer `
  -Skus 2016-Datacenter `
  -Version latest | `
Add-AzureRmVMNetworkInterface `
  -Id $nic2.Id
New-AzureRmVM `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -VM $appVmConfig

# Create the database server virtual machine configuration and virtual machine.
$databaseVmConfig = New-AzureRmVMConfig `
  -VMName myDatabaseVm `
  -VMSize Standard_DS1_V2 | `
Set-AzureRmVMOperatingSystem -Windows `
  -ComputerName mydatabaseVm `
  -Credential $cred | `
Set-AzureRmVMSourceImage `
  -PublisherName MicrosoftWindowsServer `
  -Offer WindowsServer `
  -Skus 2016-Datacenter `
  -Version latest | `
Add-AzureRmVMNetworkInterface `
  -Id $nic3.Id
New-AzureRmVM `
  -ResourceGroupName $ResourceGroupName `
  -Location $location `
  -VM $databaseVmConfig