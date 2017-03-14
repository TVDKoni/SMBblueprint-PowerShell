<#   #>
function New-FlexdeskAzureVpnCerts {
	[cmdletbinding(DefaultParameterSetName="AzureTenantDomain")]
	param(
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $ResourceGroupName,
		
		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $GatewayName,
		
		[parameter(ParameterSetName="AzureTenantId",Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $TenantId,
		
		[parameter(ParameterSetName="AzureTenantDomain",Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $TenantDomain,

		[parameter()]
		[ValidateNotNullOrEmpty()]
		[string] $SubscriptionId,
		
		[parameter()]
		[ValidateNotNullOrEmpty()]
		[string] $SubscriptionName,

		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[pscredential] $TenantCredential = (Get-Credential -Message "Please provide your tenant credentials"),

		[parameter(Mandatory=$true)]
		[ValidateNotNullOrEmpty()]
		[string] $NumClientCertificate = 10,
		
		[parameter(Mandatory=$true)]
		[string] $CertPassword = $(New-SWRandomPassword),
		
		[parameter(Mandatory=$true)]
		[string] $VpnAddressPool = "10.4.5.0/24",

		[parameter(DontShow=$true)]
		[string] $Log = $null
		)

	begin
	{
		#Check UAC, if script is started as administrator
		$myWindowsID=[System.Security.Principal.WindowsIdentity]::GetCurrent()
		$myWindowsPrincipal=new-object System.Security.Principal.WindowsPrincipal($myWindowsID)
		$adminRole=[System.Security.Principal.WindowsBuiltInRole]::Administrator
		if (-not $myWindowsPrincipal.IsInRole($adminRole))
		{
			Write-Log -Type Error -Message "You have to run this script as administrator!"
			return $null
		}

		#Check environment
		$Continue = $true
		if([string]::IsNullOrEmpty($Log) -eq $false){
			if(test-path $Log){} else {
				$Log = Start-Log
			}
		} else {
			$Log = Start-Log
		}
		$PSDefaultParameterValues = @{"Write-Log:Log"=$Log}
		if($TenantCredential){
			try {
				Connect-MsolService -Credential $TenantCredential
				$Tenant = Get-Tenant -TenantDomain $TenantDomain
				if($Tenant.Default -eq $false){
					$null = Add-AzureRMAccount -Credential $TenantCredential -TenantId $TenantId
				} else {
					$null = Add-AzureRMAccount -Credential $TenantCredential
				}

				if($SubscriptionId){
					$null = Select-AzureRmSubscription -SubscriptionId $SubscriptionId
				} elseif($SubscriptionName){
					$null = Select-AzureRmSubscription -SubscriptionName $SubscriptionName
				} else {
					# use default subscription
				}
			} catch {
				Write-Log -Type Error -Message "Error during Azure connection: $_"
			}
		}
		try{
			$null = Get-AzureRmContext
		}
		catch {
			Write-Error "No active Azure subscription is present in the session. Please use Login-AzureRMAccount and Select-AzureRMSubscription to set the target subscription, or specify Tenant/Credential information"
			return $null
		}
		
		$ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction Ignore
		if($ResourceGroup -eq $null){
			Write-Log -Type Error -Message "Resource group not found, please choose another ResourceGroupName"
			return
		}
		
		$Gateway = Get-AzureRmVirtualNetworkGateway -Name $GatewayName -ResourceGroupName $ResourceGroupName -ErrorAction Ignore
		if($Gateway -eq $null){
			Write-Log -Type Error -Message "Gateway not found, please choose another GatewayName"
			return
		}
	}
	process{
		if(!$Continue){return}

		Write-Host "Generating root certificate:"
		$rootCertificate = New-SelfSignedCertificate -Type Custom -KeySpec Signature -KeyUsageProperty Sign -KeyUsage CertSign -HashAlgorithm sha256 -KeyLength 2048 -KeyExportPolicy Exportable -CertStoreLocation "cert:\localmachine\my" -Subject "CN=$($GatewayName)_$($ResourceGroupName)_$($TenantDomain)"
		$pwd = ConvertTo-SecureString -String $CertPassword -Force -AsPlainText
		$null = Export-PfxCertificate -Cert $rootCertificate -FilePath "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_Root.pfx" -Password $pwd
		Write-Host "  $($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_Root.pfx"
		$null = Export-Certificate -Cert $rootCertificate -FilePath "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_Root.cer"
		$([Convert]::ToBase64String($rootCertificate.Export('Cert'))) | Set-Content -Path "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_RootBase64.cer"
		Write-Host "  $($TenantDomain)_$($ResourceGroupName)_$($GatewayName)__RootBase64.cer"
		
		Write-Host "Generating client certificates:"
		for($i=1; $i -le $NumClientCertificate; $i++)
		{
			$clientCertificate = New-SelfSignedCertificate -Type Custom -KeySpec Signature -HashAlgorithm sha256 -KeyLength 2048 -KeyExportPolicy Exportable -CertStoreLocation "cert:\localmachine\my" -Subject "CN=User$($i)_$($GatewayName)_$($ResourceGroupName)_$($TenantDomain)" -Signer $rootCertificate -TextExtension @("2.5.29.37={text}1.3.6.1.5.5.7.3.2")
			$null = Export-PfxCertificate -Cert $clientCertificate -FilePath "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_User$($i).pfx" -Password $pwd
			Write-Host "  $($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_User$($i).pfx"
			$null = Export-Certificate -Cert $clientCertificate -FilePath "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_User$($i).cer"
			$([Convert]::ToBase64String($clientCertificate.Export('Cert'))) | Set-Content -Path "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_User$($i)Base64.cer"
			Write-Host "  $($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_User$($i)Base64.cer"
		}

		Write-Host "Installing root certificate in VPN Gateway"
		Write-Host "  Setting VpnClientConfig"
		$vpnClientConfig = Set-AzureRmVirtualNetworkGatewayVpnClientConfig -VirtualNetworkGateway $Gateway -VpnClientAddressPool $VpnAddressPool
		Write-Host "  Adding root certificate"
		$installedCertificate = Add-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_Root.cer" -PublicCertData $([Convert]::ToBase64String($rootCertificate.Export('Cert'))) -VirtualNetworkGatewayName $GatewayName -ResourceGroupName $ResourceGroupName
		$rootCert = Get-AzureRmVpnClientRootCertificate -VpnClientRootCertificateName "$($TenantDomain)_$($ResourceGroupName)_$($GatewayName)_Root.cer" -VirtualNetworkGatewayName $GatewayName -ResourceGroupName $ResourceGroupName
		if($rootCert -eq $null){
			Write-Log -Type Error -Message "Can't install the root certificate!"
			return
		}
		
		Write-Host "Downloading VPN client."
		$downloadUrl = Get-AzureRmVpnClientPackage -ResourceGroupName $ResourceGroupName -VirtualNetworkGatewayName $GatewayName -ProcessorArchitecture Amd64
		Invoke-WebRequest -Uri $downloadUrl -OutFile "VPNClient_$($TenantDomain)_$($ResourceGroupName)_$($GatewayName).exe"
	}
	
	end{} 
}