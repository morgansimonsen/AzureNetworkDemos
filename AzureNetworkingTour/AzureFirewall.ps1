$vNetRGName = "LangskipNetwork"
$vNetName = "vNet-Langskip-WE"
$location = "westeurope"
$ResourceTags = @{"Event" = "ESPC2019"}
$FirewallName = "LangskipFirewall"
$FirewallPublicIPName = "$FirewallName-PIP"
$FirewallTrafficSourceSubnet = "Clients"
$FirewallTrafficSourceSubnetAddressPrefix = "10.1.4.0/23"
$RouteTabelName = "$FirewallTrafficSourceSubnet-route"
$FWAppRuleCollectionName = "LangskipFWAppColletion"

$VNetFirewallPIP = New-AzPublicIpAddress -Name $FirewallPublicIPName `
										-ResourceGroupName $vNetRGName `
										-Location $location `
                                        -AllocationMethod Static `
                                        -Sku Standard `
                                        -Tag $ResourceTags

$vNet = Get-AzVirtualNetwork -ResourceGroupName $vNetRGName `
                            -Name $vNetName

$FW = New-AzFirewall -Name $FirewallName `
                -ResourceGroupName $vNetRGName `
                -Location $location `
                -VirtualNetwork $vNet `
                -PublicIpAddress $VNetFirewallPIP `
                -Tag $ResourceTags

$routeConfig = New-AzRouteConfig -Name "$RouteTabelName-config" `
                                -AddressPrefix "0.0.0.0/0" `
                                -NextHopType VirtualAppliance `
                                -NextHopIpAddress $fw.IpConfigurations[0].PrivateIPAddress

$RouteTabel =  New-AzRouteTable -ResourceGroupName $RGName `
                                -Name $RouteTabelName `
                                -Location $location `
                                -Tag $ResourceTags `
                                -Route $routeConfig

Set-AzVirtualNetworkSubnetConfig -Name $FirewallTrafficSourceSubnet `
                                -VirtualNetwork $vNet `
                                -RouteTableId $RouteTabel.id `
                                -AddressPrefix $FirewallTrafficSourceSubnetAddressPrefix

$vNet | Set-AzVirtualNetwork

$AppRules = @(
    @{
        "Name"="Google"
        "Description" = "Allow traffic to Google services"
        "SourceAddress" = $FirewallTrafficSourceSubnetAddressPrefix
        "TargetFQDN"=@("*.google.com","google.com")
        "Protocol"=@("http","https")
    },
    @{
        "Name"="VG"
        "Description" = "Allow traffic to VG"
        "SourceAddress" = $FirewallTrafficSourceSubnetAddressPrefix
        "TargetFQDN"=@("*.vg.no","vg.no")
        "Protocol"=@("http","https")
    }
)

$FWAppRules = @()
ForEach ( $AppRule in $AppRules)
{
    $FWAppRules += New-AzFirewallApplicationRule  -Name $AppRule.Name `
                                -Description $AppRule.Description `
                                -SourceAddress $AppRule.SourceAddress `
                                -TargetFqdn $AppRule.TargetFQDN `
                                -Protocol $AppRule.Protocol
}

$FWAppRuleCollection = New-AzFirewallApplicationRuleCollection -Name $FWAppRuleCollectionName `
                                            -Priority 200 `
                                            -ActionType Allow `
                                            -Rule $FWAppRules `
                                            -Zone 1,2,3

$FW.ApplicationRuleCollections = $FWAppRuleCollection

Set-AzFirewall -AzureFirewall $FW