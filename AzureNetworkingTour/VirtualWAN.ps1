$vNetRGName = "LangskipNetwork"
$vNetName = "vNet-Langskip-NE"
$location = "northeurope"
$ResourceTags = @{"Event" = "ESPC2019"}
$vWANName = "LangskipWAN"
$HubName = "LangskipvWANHubNE"
$HubAddressPrefix = "10.200.0.0/16"

$vWAN = New-AzVirtualWan -ResourceGroupName $vNetRGName `
                -Name $vWANName `
                -Location $location `
                -AllowVnetToVnetTraffic `
                -AllowBranchToBranchTraffic `
                -Tag $ResourceTags `
                -VirtualWANType Standard

New-AzVirtualHub -ResourceGroupName $vNetRGName `
                -Name $HubName `
                -VirtualWan $vWAN `
                -AddressPrefix $HubAddressPrefix `
                -Location $location `
                -Tag $ResourceTags