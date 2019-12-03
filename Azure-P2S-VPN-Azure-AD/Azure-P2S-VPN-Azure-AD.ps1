# Consent to Azure AD VPN client app
Start-Process "https://login.microsoftonline.com/common/oauth2/authorize?client_id=41b23e61-6c1e-4545-b367-cd054e0ed4b4&response_type=code&redirect_uri=https://portal.azure.com&nonce=1234&prompt=admin_consent"

$AzureADTenantId = "8fec7cb8-30e7-4d8a-98ae-6e64853af4a3"
$RGName = "LangskipNetwork"
$vNetName = "vNet-Langskip-WE"
$vNetLocation = "West Europe"
$ResourceTags = @{"Event" = "ESPC2019"}
$VNetGWName = $vNetName+"-GW"
$vNetGWPIPName = $VNetGWName+"-PIP"
$VNetGWIPConfigName = $VNetGWName+"-IPConfig"
$VPNClientAddressPool = "192.168.201.0/24"

$RG = Get-AzResourceGroup -Name $RGName

# Create GW
$VNet = Get-AzVirtualNetwork -ResourceGroupName $RGName -Name $vNetName
$GatewaySubnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $VNet

$VNetGWPIP = New-AzPublicIpAddress -Name $vNetGWPIPName `
										-ResourceGroupName $RG.ResourceGroupName `
										-Location $vNetLocation `
										-AllocationMethod Dynamic `
                                        -Tag $ResourceTags

$VNetGWIPConfig = New-AzVirtualNetworkGatewayIpConfig -Name $VNetGWIPConfigName `
															-Subnet $GatewaySubnet `
															-PublicIpAddress $VNetGWPIP

$VNetGW = New-AzVirtualNetworkGateway -Name $VNetGWName `
											-ResourceGroupName $RG.ResourceGroupName `
											-Location $vNetLocation `
											-IpConfigurations $VNetGWIPConfig `
											-GatewayType Vpn `
											-GatewaySku VpnGw1 `
											-VpnType RouteBased `
											-Tag $ResourceTags

Set-AzVirtualNetworkGateway -VirtualNetworkGateway $VNetGW `
							-VpnClientProtocol "OpenVPN" `
							-VpnClientAddressPool $VPNClientAddressPool

$VNetGW = Get-AzVirtualNetworkGateway -Name $VNetGWName -ResourceGroupName $RGName

Set-AzVirtualNetworkGateway -VirtualNetworkGateway $VNetGW `
                            -AadTenantUri "https://login.microsoftonline.com/$AzureADTenantId" `
                            -AadAudienceId "41b23e61-6c1e-4545-b367-cd054e0ed4b4" `
                            -AadIssuerUri "https://sts.windows.net/$AzureADTenantId/"

# VPN Profile
$VPNProfile = New-AzVpnClientConfiguration -ResourceGroupName $RGName `
                                        -Name $VNetGWName `
                                        -AuthenticationMethod "EapTls"

$VPNProfileFileName = "$VNetGWName-vpnclientconfiguration.zip"
Invoke-WebRequest -Uri $VPNProfile.VpnProfileSASUrl -OutFile $VPNProfileFileName

Expand-Archive -Path $VPNProfileFileName