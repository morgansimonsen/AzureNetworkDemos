<#
GlobalVirtualNetworkPeering.ps1



#>

$location = "westcentralus"
$ResourceGroupName = "FakeBeerBackEnd"
New-AzureRmResourceGroup -Name $ResourceGroupName -Location $location

# Create network
Write-Output "Creating vNet..."
$vNetName = "StandardLBvNet" 
# Create a subnet configuration
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name "database" -AddressPrefix 10.1.1.0/24

# Create a virtual network
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Location $location `
    -Name $vNetName -AddressPrefix 10.1.0.0/16 -Subnet $subnetConfig

exit
$VM1Name = "DBVM1"
$VM2Name = "DBVM2"

# Create a public IP address and specify a DNS name
Write-Output "Creating VM Public IPs..."
$pip1 = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "$VM1Name-PIP"
$pip2 = New-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Location $location `
    -AllocationMethod Static -IdleTimeoutInMinutes 4 -Name "$VM2Name-PIP"

# Create NSG
Write-Output "Creating NSG..."
# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleRDP  -Protocol Tcp `
    -Direction Inbound -Priority 1000 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 3389 -Access Allow

# Create an inbound network security group rule for port 80
$nsgRuleSql = New-AzureRmNetworkSecurityRuleConfig -Name myNetworkSecurityGroupRuleWWW  -Protocol Tcp `
    -Direction Inbound -Priority 1001 -SourceAddressPrefix * -SourcePortRange * -DestinationAddressPrefix * `
    -DestinationPortRange 1433 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $ResourceGroupName -Location $location `
    -Name "DBServerNSG" -SecurityRules $nsgRuleRDP,$nsgRuleSql

# Create a virtual network card and associate with public IP address and NSG
Write-Output "Creating NICs..."
$VM1NIC1 = New-AzureRmNetworkInterface -Name "$VM1Name-NIC1" -ResourceGroupName $ResourceGroupName -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip1.Id -NetworkSecurityGroupId $nsg.Id

$VM2NIC1 = New-AzureRmNetworkInterface -Name "$VM2Name-NIC1" -ResourceGroupName $ResourceGroupName -Location $location `
    -SubnetId $vnet.Subnets[0].Id -PublicIpAddressId $pip2.Id -NetworkSecurityGroupId $nsg.Id

$StandardLBAvailabilitySet = New-AzureRmAvailabilitySet -ResourceGroupName $ResourceGroupName -Name "StandardLBAvailabilitySet" -Location $location -Sku "Aligned" -PlatformUpdateDomainCount "2" -PlatformFaultDomainCount "2"

# Define a credential object
$cred = Get-Credential
$VMSize = "Standard_DS2_v2"

Write-Output "Creating VMs..."
# Create a VM1
$VM1Config = New-AzureRmVMConfig -VMName $VM1Name -VMSize $VMSize -AvailabilitySetId $StandardLBAvailabilitySet.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName "VM1" -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $VM1NIC1.Id -Primary
New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $VM1Config

# Create a VM2
$VM2Config = New-AzureRmVMConfig -VMName $VM2Name -VMSize $VMSize -AvailabilitySetId $StandardLBAvailabilitySet.Id | `
    Set-AzureRmVMOperatingSystem -Windows -ComputerName "VM2" -Credential $cred | `
    Set-AzureRmVMSourceImage -PublisherName MicrosoftWindowsServer -Offer WindowsServer `
    -Skus 2016-Datacenter -Version latest | Add-AzureRmVMNetworkInterface -Id $VM2NIC1.Id -Primary

New-AzureRmVM -ResourceGroupName $ResourceGroupName -Location $location -VM $VM2Config

exit
# Load Balancer Public IPs
Write-Output "Creating Standard Load Balancer..."
$LBName = "FakeBeerDBStandardLB"
$publicIP1 = New-AzureRmPublicIpAddress -Name "$LBName-PIP1" -ResourceGroupName $ResourceGroupName -Location $location -AllocationMethod Dynamic -DomainNameLabel fakebeerdb

$publicIP1 = Get-AzureRmPublicIpAddress -Name "$LBName-PIP1" -ResourceGroupName $ResourceGroupName

$frontendIP1 = New-AzureRmLoadBalancerFrontendIpConfig -Name dharmabeerfe -PublicIpAddress $publicIP1

$beaddresspool1 = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name dharmabeerpool
$beaddresspool2 = New-AzureRmLoadBalancerBackendAddressPoolConfig -Name duffbeerpool

$healthProbe = New-AzureRmLoadBalancerProbeConfig -Name HTTP -RequestPath 'index.html' -Protocol http -Port 80 -IntervalInSeconds 15 -ProbeCount 2

$lbrule1 = New-AzureRmLoadBalancerRuleConfig -Name HTTP_dharmabeer -FrontendIpConfiguration $frontendIP1 -BackendAddressPool $beaddresspool1 -Probe $healthprobe -Protocol Tcp -FrontendPort 80 -BackendPort 80
$lbrule2 = New-AzureRmLoadBalancerRuleConfig -Name HTTP_duffbeer -FrontendIpConfiguration $frontendIP2 -BackendAddressPool $beaddresspool2 -Probe $healthprobe -Protocol Tcp -FrontendPort 80 -BackendPort 80

$mylb = New-AzureRmLoadBalancer -ResourceGroupName $ResourceGroupName -Name $LBName -Location $location -Sku Standard -FrontendIpConfiguration $frontendIP1 -LoadBalancingRule $lbrule1 -BackendAddressPool $beaddresspool1 -Probe $healthProbe

$mylb = Get-AzureRmLoadBalancer -Name $LBName -ResourceGroupName $ResourceGroupName | Add-AzureRmLoadBalancerBackendAddressPoolConfig -Name duffbeerpool | Set-AzureRmLoadBalancer

$mylb | Add-AzureRmLoadBalancerFrontendIpConfig -Name duffbeerfe -PublicIpAddress $publicIP2 | Set-AzureRmLoadBalancer

Add-AzureRmLoadBalancerRuleConfig -Name HTTP -LoadBalancer $mylb -FrontendIpConfiguration $frontendIP2 -BackendAddressPool $beaddresspool2 -Probe $healthProbe -Protocol Tcp -FrontendPort 80 -BackendPort 80 | Set-AzureRmLoadBalancer

#$nic1 = Get-AzureRmNetworkInterface -Name "VM1-NIC2" -ResourceGroupName $ResourceGroupName
#$nic2 = Get-AzureRmNetworkInterface -Name "VM2-NIC2" -ResourceGroupName $ResourceGroupName

$VM1NIC2.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($mylb.BackendAddressPools[0]);
$VM1NIC2.IpConfigurations[1].LoadBalancerBackendAddressPools.Add($mylb.BackendAddressPools[1]);
$VM2NIC2.IpConfigurations[0].LoadBalancerBackendAddressPools.Add($mylb.BackendAddressPools[0]);
$VM2NIC2.IpConfigurations[1].LoadBalancerBackendAddressPools.Add($mylb.BackendAddressPools[1]);

$mylb = $mylb | Set-AzureRmLoadBalancer

$VM1NIC2 | Set-AzureRmNetworkInterface
$VM2NIC2 | Set-AzureRmNetworkInterface

