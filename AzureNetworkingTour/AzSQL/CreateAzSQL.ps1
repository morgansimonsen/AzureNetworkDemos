$RGName = "LangskipDatabase"
$Location = "westeurope"
$SQLServerName = "LangskipWebDBSrv1"
$SQLDatabaseName = "LangskipWebCommerce1"
$adminSqlLogin = "LangskipSqlAdmin"

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

$DBRG = New-AzResourceGroup -Name $RGName -Location $Location

# Create a server with a system wide unique server name
$server = New-AzSqlServer -ResourceGroupName $RGName `
    -ServerName $SQLServerName `
    -Location $location `
    -SqlAdministratorCredentials $(New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList $adminSqlLogin, $(ConvertTo-SecureString -String $password -AsPlainText -Force))

# Create a server firewall rule that allows access from the specified IP range
#$serverFirewallRule = New-AzSqlServerFirewallRule -ResourceGroupName $resourceGroupName `
#    -ServerName $serverName `
#    -FirewallRuleName "AllowedIPs" -StartIpAddress $startIp -EndIpAddress $endIp

# Create a blank database with an S0 performance level
$database = New-AzSqlDatabase  -ResourceGroupName $RGName `
    -ServerName $SQLServerName `
    -DatabaseName $SQLDatabaseName `
    -RequestedServiceObjectiveName "S0" `
    -SampleName "AdventureWorksLT"

Write-Information -MessageData $password -InformationAction Continue