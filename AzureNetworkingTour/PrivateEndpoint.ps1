$vNetRGName = "LangskipNetwork"
$vNetName = "vNet-Langskip-WE"
$subnetname = "PrivateLink"
$PrivateLinkRGName = "LangskipDatabase"
$location = "westeurope"
$PrivateLinkConnectionName = "LangskipSqlPrivateLinkConnection"
$PrivateLinkEndpointName = "LangskipSQLPrivateEndpoint"
$AzSQLServerName = "LangskipWebDBSrv1"
$ResourceTags = @{"Event" = "ESPC2019"}

$AzSQLServer = Get-AzSqlServer -ResourceGroupName $PrivateLinkRGName `
                            -ServerName $AzSQLServerName

$privateEndpointConnection = New-AzPrivateLinkServiceConnection -Name $PrivateLinkConnectionName `
                                                                -PrivateLinkServiceId $AzSQLServer.ResourceId `
                                                                -GroupId "sqlServer" -Tag $ResourceTags

$virtualNetwork = Get-AzVirtualNetwork -ResourceGroupName $vNetRGName -Name $vNetName

$subnet = $virtualNetwork `
    | Select -ExpandProperty subnets `
    | Where-Object  { $_.Name -eq $subnetname }

# disable pl policies
# https://docs.microsoft.com/en-us/azure/private-link/disable-private-endpoint-network-policy
($virtualNetwork | Select -ExpandProperty subnets | Where-Object  {$_.Name -eq $subnetname} ).PrivateEndpointNetworkPolicies = "Disabled" 
$virtualNetwork | Set-AzVirtualNetwork

New-AzPrivateEndpoint -ResourceGroupName $PrivateLinkRGName `
    -Name $PrivateLinkEndpointName `
    -Location $location `
    -Subnet $subnet `
    -PrivateLinkServiceConnection $privateEndpointConnection -Tag $ResourceTags