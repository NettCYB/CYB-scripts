
<#

.SYNOPSIS
Add Chrome Extensions to PC via Powershell

.PARAMETER Extension
String value of an extension ID taken from the Chrome Web Store URL for the extension

.EXAMPLE
This will install chrome extension to the HKCU hive
New-ChromeExtension -Extension 'ohkeehjepccedbdpohnbapepongppfcj' -Hive 'Machine'

This will uninstall chrome extension from all Hives
New-ChromeExtension -Remove 'ohkeehjepccedbdpohnbapepongppfcj'

#>

[cmdletBinding()]
Param(
	[String[]]$Extension,
	[ValidateSet('Machine', 'User')]
	[String]$Hive,
	[String]$Remove
)

  
$regLocation = 'Software\Policies\Google\Chrome\ExtensionInstallForcelist'
$HKLMRegLocation = "HKLM:\$regLocation"
$HKCURegLocation = "HKCU:\$regLocation"

if ($PSBoundParameters.ContainsKey('Remove'))
{	
	#remove from HKLM
	$extensionInstallForceListEntriesHKLM = Get-ItemProperty -Path $HKLMRegLocation
	foreach ($property in $extensionInstallForceListEntriesHKLM.PSObject.Properties)
	{
		if ($property.value -Like "$Remove*") {
			Write-Host "Removing the extension with id $Remove and registry id:  $property.name"
			Remove-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' -Name $property.name
		}
	}
	
	#remove from HKCU
#	$extensionInstallForceListEntriesHKCU = Get-ItemProperty -Path $HKCURegLocation
#	foreach ($property in $extensionInstallForceListEntriesHKCU.PSObject.Properties)
#	{
#		if ($property.value -Like "$Remove*") {
#			Write-Host "Removing the extension with id $Remove and registry id:  $property.name"
#			Remove-ItemProperty -Path Registry::'HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Google\Chrome\ExtensionInstallForcelist' -Name $property.name
#		}
#	}
}
else
{
	#Target HKLM or HKCU depending on whether you want to affect EVERY user, or just a single user.
	#If using HKCU, you'll need to run this script in that user context.
	Switch ($Hive) {
		'Machine' {
			If (!(Test-Path "HKLM:\$regLocation")) {
				Write-Verbose -Message "No Registry Path, setting count to: 0"
				[int]$Count = 0
				Write-Verbose -Message "Count is now $Count" 
				New-Item -Path "HKLM:\$regLocation" -Force
			}
	
			Else {
				Write-Verbose -Message "Keys found, counting them..."
				#[int]$Count = (Get-Item "HKLM:\$regLocation").Count
				$indexes = @(0)
				$extensionPropEntries = Get-ItemProperty -Path $HKLMRegLocation
				foreach ($property in $extensionPropEntries.PSObject.Properties)
				{	
					Try
					{
						$num = [int]$property.name
						$indexes += $num
					}
					Catch
					{
						#ignore
					}
				}
				[int]$Count = ($indexes | sort | Select-Object -Last 1)
				Write-Verbose -Message "Count is now $Count"
			}
		}
		
		'User' {
			If (!(Test-Path "HKCU:\$regLocation")) {
				
				Write-Verbose -Message "No Registry Path, setting count to: 0"
				[int]$Count = 0
				Write-Verbose -Message "Count is now $Count" 
				New-Item -Path "HKCU:\$regLocation" -Force
	
			}
	
			Else {
				
				Write-Verbose -Message "Keys found, counting them..."
				#[int]$Count = (Get-Item "HKCU:\$regLocation").Count
				$indexes = @(0)
				$extensionPropEntries = Get-ItemProperty -Path $HKCURegLocation
				foreach ($property in $extensionPropEntries.PSObject.Properties)
				{	
					Try
					{
						$num = [int]$property.name
						$indexes += $num
					}
					Catch
					{
						#ignore
					}
				}
				[int]$Count = ($indexes | sort | Select-Object -Last 1)
				Write-Verbose -Message "Count is now $Count"
			
			}
		}
	}

	$regKey = $Count + 1
	
	Write-Verbose -Message "Creating reg key with value $regKey"
	
	$regData = "$Extension;https://clients2.google.com/service/update2/crx"

	Switch ($Hive) {
		
		'Machine' { New-ItemProperty -Path "HKLM:\$regLocation" -Name $regKey -Value $regData -PropertyType STRING -Force }
		'User' { New-ItemProperty -Path "HKCU:\$regLocation" -Name $regKey -Value $regData -PropertyType STRING -Force }
	
	}
}

