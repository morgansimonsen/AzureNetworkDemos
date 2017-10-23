<#
New-StorageAccountvNetServiceEndpoint.ps1
#>

$subscriptionId = "3cf46281-f639-44bc-a338-11697697bb2a"
# The Azure region where all resources will be created
$Location = "WestUS2"
# New or existing resource group where the network hub will be created
$RGNamevNetServiceEndpoints = "RG-vNet-Service-Endpoints"
 # Name of the new vNet to create
$VNetHubName = "vDC-Hub-Network"
# Address space of the new vNet
$VNetHubAddressSpace = "10.0.0.0/16"
# ASN
$VNetASN = 65010 # seems not allowed to set the default ASN of 65515...
# On-premises Public IP
$OnPremPublicIP = "85.167.121.198"
# On-premises address space
$OnPremAddressSpace = "192.168.0.0/16"
# On-premises ASN
$OnPremASN = 65050
# On-premises network name
$OnPremNetworkName = "Furuvegen8"
# On-premises perfixes to announce
$OnPremBGPPrefixes = "10.52.255.254/32"
$OnPremBGPPeerIP = "10.52.255.254"

# Collection of subnets to create in the vNet
$HubSubnets = @{
    "GatewaySubnet" = "10.0.255.0/26"
    "external"  = '10.0.1.0/24'
    "internal" = '10.0.2.0/24'
    "servers"  = '10.0.100.0/24'
    "clients" = '10.0.101.0/24'
    "management" = '10.0.102.0/24'
}

$ServiceEndpointSubnets = ("internal","servers","clients","management")
#$DNSIPs = "10.83.254.203", "10.83.254.204", "10.83.254.205", "10.83.254.206"
#$DNSIPs = "208.67.222.220", "208.67.222.222"


# Tags
$ResourceTags = @{ "System ID"="0000"; "Cost Center ID"="0000" }
# ======= End of variable area =======

#Set-AzureRmContext -Subscription $subscriptionName
Select-AzureRmSubscription -SubscriptionId $subscriptionId

$RG = New-AzureRmResourceGroup -Name $RGNamevNetServiceEndpoints -Location $Location -Tag $ResourceTags


