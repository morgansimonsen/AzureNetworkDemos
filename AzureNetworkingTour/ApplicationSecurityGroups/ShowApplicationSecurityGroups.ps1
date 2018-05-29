 <#
ShowApplicationSecurityGroup.ps1



#>
$ResourceGroupName = "RGApplicationSecurityGroup"
get-AzureRmApplicationSecurityGroup -ResourceGroupName $ResourceGroupName
Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName | select -ExpandProperty IpConfigurations
$vnet = Get-AzureRmVirtualNetwork -ResourceGroupName $ResourceGroupName -Name "myVnet"
Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork $vnet -Name "mySubnet"
