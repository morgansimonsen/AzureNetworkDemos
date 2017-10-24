# Provision AWS resources for connection to Azure

# Public IP address of Azure vNet GW
$AzureVNetGWPublicIP = "40.69.206.156"
$AzureVNetGWASN = "65515"

# Get existing VPC GW
$AWSVPNGW = Get-EC2VpnGateway -VpnGatewayId vgw-fecdff8a

# Create new AWS Customer GW
$AWSCustomerGW = New-EC2CustomerGateway -BgpAsn $AzureVNetGWASN -PublicIp $AzureVNetGWPublicIP -Type ipsec.1
New-EC2Tag -Resource $AWSCustomerGW.CustomerGatewayId -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -Property @{"Key" = "Name";"Value" = "AzureVNetGW"})

# Create new AWS VPN connection
# (This costs money)
$AWSVPNConnection = New-EC2VpnConnection -CustomerGatewayId $AWSCustomerGW.CustomerGatewayId -VpnGatewayId $AWSVPNGW.VpnGatewayId -Type ipsec.1
New-EC2Tag -Resource $AWSVPNConnection.VpnConnectionId -Tag (New-Object -TypeName Amazon.EC2.Model.Tag -Property @{"Key" = "Name";"Value" = "AWS-VPC-GW"})

# Parse XML to find pre-shared key
[xml]$AWSCustomerGatewayConfiguration = $AWSVPNConnection.CustomerGatewayConfiguration
$AWSPublicIP = $AWSCustomerGatewayConfiguration.vpn_connection.vpn_gateway.tunnel_outside_address.ip_address[0]
$AWSBGPPeerIP = $AWSCustomerGatewayConfiguration.vpn_connection.vpn_gateway.tunnel_inside_address.ip_address[0]
$AWSASN = $AWSCustomerGatewayConfiguration.vpn_connection.vpn_gateway.bgp.asn[0]
$IPSecPreSharedKey = $AWSCustomerGatewayConfiguration.vpn_connection.ipsec_tunnel.ike.pre_shared_key[0]

Write-Output ("AWS Public IP    :"+$AWSPublicIP)
Write-Output ("IPSec Shared key :"+$IPSecPreSharedKey)