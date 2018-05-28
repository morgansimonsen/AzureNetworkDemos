<#
https://docs.microsoft.com/en-us/azure/dns/private-dns-getstarted-powershell
#>

$RG = "PuppetLabRG"
$VNET = "PuppetLabVNet"
$dNSZone = "muppet.local"
# Resolution vnet
$vnet = Get-AzureRmVirtualNetwork -Name $VNET -ResourceGroupName $RG
New-AzureRmDnsZone -Name $dNSZone -ResourceGroupName $RG -ZoneType Private -ResolutionVirtualNetworkId @($vnet.Id)

# Registration vnet
$vnet = Get-AzureRmVirtualNetwork -Name $VNET -ResourceGroupName $RG
New-AzureRmDnsZone -Name $dNSZone -ResourceGroupName $RG -ZoneType Private -RegistrationVirtualNetworkId @($vnet.Id)

# show existing
$vnet = Get-AzureRmVirtualNetwork -Name $VNET -ResourceGroupName $RG
Get-AzureRmDnsZone -ResourceGroupName $RG