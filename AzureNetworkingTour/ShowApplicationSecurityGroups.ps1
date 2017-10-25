 <#
ShowApplicationSecurityGroup.ps1



#>
$ResourceGroupName = "RGApplicationSecurityGroup"
get-AzureRmApplicationSecurityGroup -ResourceGroupName $ResourceGroupName
Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroupName | select -ExpandProperty IpConfigurations
