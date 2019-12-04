$RGName = "LangskipServers"
$vNetRGName = "LangskipNetwork"
$vNetName = "vNet-Langskip-WE"
$subnetName = "Servers-Dynamic"
$Location = "West Europe"
$ResourceTags = @{"Event" = "ESPC2019"}
$VMName = "ls-web-2"
$VMSize = "Standard_A0"
$NICName = "$VMName-NIC"

Function Get-RandomAlphanumericString {
	
	[CmdletBinding()]
	Param (
        [int] $length = 8
	)

	Begin{
	}

	Process{
        Write-Output ( -join ((0x30..0x39) + ( 0x41..0x5A) + ( 0x61..0x7A) | Get-Random -Count $length  | % {[char]$_}) )
	}	
}

$password = Get-RandomAlphanumericString -length 16

# Define user name and blank password
$securePassword = ConvertTo-SecureString $password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ("azureuser", $securePassword)

# NIC
$vNet = Get-AzVirtualNetwork -ResourceGroupName $vNetRGName `
                            -Name $vNetName


$NIC = New-AzNetworkInterface -Name $NICName `
                            -ResourceGroupName $RGName `
                            -Location $Location `
                            -SubnetId ( $VNet.Subnets | where { $_.Name -eq $subnetName } ).id

$VM = New-AzVMConfig -VMName $VMName `
                    -VMSize $VMSize
$VM = Set-AzVMOperatingSystem -VM $VM `
                            -Windows `
                            -ComputerName $VMName ` `
                            -EnableAutoUpdate `
                            -Credential $cred

$VM = Add-AzVMNetworkInterface -VM $VM -Id $NIC.Id
$VM = Set-AzVMSourceImage -VM $VM `
                        -PublisherName 'MicrosoftWindowsServer' `
                        -Offer 'WindowsServer' `
                        -Skus "2019-Datacenter" `
                        -Version latest

New-AzVm `
    -ResourceGroupName $RGName `
    -VM $VM `
    -Location $Location `
    -Tag $ResourceTags

Write-Information -MessageData $password -InformationAction Continue

Install-WindowsFeature -name Web-Server -IncludeManagementTools