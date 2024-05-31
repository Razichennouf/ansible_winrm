<#PSScriptInfo
.SYNOPSIS
WinRM Deployment Utilities

.DESCRIPTION
This script provides a comprehensive set of automation utilities for managing WinRM configurations.

.VERSION 1.0

.AUTHOR
Razi chennouf
#>
function Enable-PowerShellRemoting {
    Enable-PSRemoting -Force
    Write-Host "PowerShell Remoting Enabled"
}

function Configure-WinRMClient {
    	Set-Item -Path 'WSMan:\localhost\Client\Auth\Certificate' -Value $false
	Set-Item -Path 'WSMan:\localhost\Client\AllowUnencrypted' -Value $false
	Set-Item -Path 'WSMan:\localhost\Client\Auth\Basic' -Value $false
	Set-Item -Path 'WSMan:\localhost\Client\Auth\CredSSP' -Value $false
	Set-Item -Path 'WSMan:\localhost\Client\Auth\Kerberos' -Value $false
    Write-Host "WinRM Client Configured"
}

function Configure-WinRMServer {
        Set-Item -Path 'WSMan:\localhost\Service\Auth\Certificate' -Value $false
	Set-Item -Path 'WSMan:\localhost\Service\AllowUnencrypted' -Value $false
	Set-Item -Path 'WSMan:\localhost\Service\Auth\Basic' -Value $true
	Set-Item -Path 'WSMan:\localhost\Service\Auth\CredSSP' -Value $true
	Set-Item -Path 'WSMan:\localhost\Service\Auth\Kerberos' -Value $false
    Write-Host "WinRM Server Configured"
}

function Configure-AWSSpecificSettings {
    $environment = Read-Host "Are you using AWS? (Type 'yes' or 'no')"

	if ($environment -eq "yes") {
		$Password = Read-Host "Enter the new password" -AsSecureString
		$UserAccount = Get-LocalUser -Name "Administrator"
		$UserAccount | Set-LocalUser -Password $Password
	}
	elseif ($environment -eq "no") {
		Write-Host "Check and persist a password with a no expiration date"
	}
	else {
	    Write-Host "Invalid input. Please type 'yes' or 'no' to choose the environment."
	}

    Write-Host "Administrator password is now persistent"
}

function Configure-Firewall {
	    Write-Host " Enabling WinRM ports for both IPv4 and IPv6 on the local server..."
	    New-NetFirewallRule -DisplayName "Allow WinRM HTTPS IPv4" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow
	    # Later to fix we need to enable IPV6 because somme softwares needs IPV6 to work
		#New-NetFirewallRule -DisplayName "Allow WinRM HTTPS IPv6" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow -LocalAddress ::/0
    Write-Host "WinRM HTTPS ports enabled for both IPv4 and IPv6."
    Write-Host "Firewall Rules Configured"
}

function Get-SecurePassword {
    param (
        [string]$Prompt = "Enter a strong password for the user "
    )

    $ValidPassword = $false
    $securePassword = $null

    while (-not $ValidPassword) {
        $securePassword = Read-Host -AsSecureString -Prompt $Prompt

        # Check if the password meets the complexity requirements
        $isValidPassword = $securePassword | ConvertTo-SecureString -AsPlainText -Force
        if ($isValidPassword) {
            $ValidPassword = $true
        } else {
            Write-Host "Password does not meet the complexity requirements. Please try again."
        }
    }

    return $securePassword
}
function SetupAutomationUser {

    $username = Read-Host "Enter the username for the new automation user"
    $password = Get-SecurePassword
    try {
    New-LocalUser -Name $username -Password $password -PasswordNeverExpires
    Write-Host "User '$username' has been created."
	} catch {
	    Write-Host "Error creating user: $_"
	}
    # Optional but Must do if in production !!!! be carefull
       # !!!!!!! (dont give those group permissions to the user) Add user to Administrators and Remote Management Users groups (Optional) 
       # net localgroup Administrators $username /add #Dont do this in production
    Write-Host "Automation User Setup Done"
}


function Manage-Certificate {
    param (
        [Parameter(Mandatory=$true)]
        [string]$IPAddress,

        [string]$ExportFilePath = "C:\Users\Administrator\certificate.cer"
    )
     # Check if a certificate for the given IP already exists
    $existingCertificate = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.DnsNameList -contains $IPAddress -or $_.Subject -match "CN=$IPAddress" }
    if ($existingCertificate) {
        Write-Host "A certificate for IP: $IPAddress with thumbprint $($existingCertificate.Thumbprint) already exists."
        return
    }
    
    # Create a new self-signed certificate
    $global:newCertificate = New-SelfSignedCertificate -DnsName $IPAddress -CertStoreLocation Cert:\LocalMachine\My
    if (-not $global:newCertificate) {
        Write-Host "Failed to create a new certificate."
        return
    }
    
    Write-Host "Created new certificate for IP: $IPAddress with thumbprint: ""$global:newCertificate.Thumbprint"")"

    # Export the certificate to the specified file
    $global:newCertificate | Export-Certificate -FilePath $ExportFilePath -Force
    Write-Host "Certificate exported to: $ExportFilePath"

    # Import the exported certificate to the Trusted Root Certification Authorities store
    Import-Certificate -FilePath $ExportFilePath -CertStoreLocation Cert:\LocalMachine\Root
    Write-Host "Certificate imported to Trusted Root Certification Authorities store."

    # Clean up
    Remove-Item $ExportFilePath -Force
    Write-Host "Certificate file deleted from: $ExportFilePath"
    
    
    Write-Host "Certificates managed successfully for IP: $IPAddress"
}


function Configure-Winrm {
    # Configure TrustedHosts On client side (Ansible)
    Write-Host "Trusting All Hosts..."
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
   
    Set-Service WinRM -StartupType 'Automatic'
    
    winrm delete winrm/config/listener?Address=*+Transport=HTTP
    winrm delete winrm/config/listener?Address=*+Transport=HTTPS
    # Create Listener
	# Configure WinRM to use HTTPS and create a listener
	$hostname=$serverIP
	$Thumbprint=$global:newCertificate.Thumbprint
	$command = "winrm create winrm/config/listener?Address=*+Transport=HTTPS '@{Hostname=""$hostname"";CertificateThumbprint=""$Thumbprint"";port=""5986""}'"
	Invoke-Expression $command
	
	Restart-Service WinRM
    Write-Host "WinRM Configured"
}


# Administration section 
function Get-Certificates {
    # Get the certificates from the LocalMachine\My store
    $certificates = Get-ChildItem -Path "Cert:\LocalMachine\My"

    # Display the certificate information
    if ($certificates.Count -gt 0) {
        foreach ($cert in $certificates) {
            Write-Host "Certificate Subject: $($cert.Subject)"
            Write-Host "Thumbprint: $($cert.Thumbprint)"
            Write-Host "Issuer: $($cert.Issuer)"
            Write-Host "NotBefore: $($cert.NotBefore)"
            Write-Host "NotAfter: $($cert.NotAfter)"
            Write-Host "----------------------"
        }
    } else {
        Write-Host "No certificates found in the LocalMachine\My store."
    }
}

function Get-WinrmConfig {
winrm get winrm/config
}
function Check-WinrmListeners {
    $result = netstat -ano | findstr ":5986"

    if (-not $result) {
        Write-Host "The listener is not set up on port 5986." -ForegroundColor Red
    } else {
        Write-Host $result
    }
}

function User-PermissionGroup {
Set-PSSessionConfiguration -ShowSecurityDescriptorUI -Name Microsoft.PowerShell
}
function Add-DynamicLocalGroupMember {
    param (
        [string]$GroupName = (Read-Host "Enter the group name (e.g., 'Remote Management Users')"),
        [string]$MemberName = (Read-Host "Enter the member name (e.g., 'Administrator')")
    )

    # Check if the group exists
    if (-not (Get-LocalGroup -Name $GroupName -ErrorAction SilentlyContinue)) {
        Write-Host "The group $GroupName does not exist!" -ForegroundColor Red
        return
    }

    # Check if the user exists
    if (-not (Get-LocalUser -Name $MemberName -ErrorAction SilentlyContinue)) {
        Write-Host "The user $MemberName does not exist!" -ForegroundColor Red
        return
    }

    # Add the member to the group
    Add-LocalGroupMember -Group $GroupName -Member $MemberName

    Write-Host "Added $MemberName to $GroupName successfully!" -ForegroundColor Green
}

function Get-GroupMembers {
    param(
        [Parameter(Mandatory=$true)]
        [string]$GroupName
    )
    net localgroup $GroupName
}
function Get-LocalUsers {
Get-LocalUser
}

function Delete-Certificate {
    param (
        [string]$Thumbprint
    )

    # Get the certificate by thumbprint from the LocalMachine\My store
    $certificate = Get-ChildItem -Path "Cert:\LocalMachine\My" | Where-Object { $_.Thumbprint -eq $Thumbprint }

    if ($certificate) {
        # Delete the certificate
        $certificate | Remove-Item
        Write-Host "Certificate with thumbprint '$Thumbprint' has been deleted."
    } else {
        Write-Host "Certificate with thumbprint '$Thumbprint' not found."
    }
}

function Delete-WinrmListeners {
	winrm delete winrm/config/listener?Address=*+Transport=HTTP
    	winrm delete winrm/config/listener?Address=*+Transport=HTTPS
}

# Menu
function Show-Menu {
    param(
        [string]$Title = 'WinRM Deployment Utilities',
        [string]$Title2 = 'WinRM Admin Utilities'
    )
	Clear-Host
	# Prompt user for input
 	Write-Host -ForegroundColor "* | Everything Ends with a star* should be mandatory "
	Write-Host -ForegroundColor 14 "| You need to give attention if you are using AWS or you does not use a CP check the HINT"
	Write-Host "|____ If you are using AWS, Before starting Go to SG (Security Group) and enable WINRM-HTTPS port"
	Write-Host "|____ If you are not using AWS choose option 5 to configure the Local firewall rules"
	Write-Host ""
    Write-Host "================ $Title ================"

    Write-Host "1: Enable PowerShell Remoting*"
    Write-Host "2: Configure WinRM Client*"
    Write-Host "3: Configure WinRM Server*"
    Write-Host "4: AWS User Persisting Password <- Only when using AWS"
    Write-Host "5: Configure Firewall*"
    Write-Host "6: Setup Automation User"
    Write-Host "7: Manage Certificates*"
    Write-Host "8: Configure WinRM*"
    Write-Host "================ $Title2 ================"
    Write-Host "9: Delete all winrm listeners" 
    Write-Host "10: List all available Certificates"
    Write-Host "11: Delete a certificate"
    Write-Host "12: List  winrm configuration"
    Write-Host "13: List all winrm listeners"
    Write-Host "14: Check permission group"
    Write-Host "15: Get members of specific group"
    Write-Host "16: List all available users with description"
    Write-Host "17: Add a specific user to a specific group"
    Write-Host "Q: Quit"
}

do {
    Show-Menu
    $input = Read-Host "Please make a selection"
    switch ($input) {
        '1' {
            Enable-PowerShellRemoting
            break
        }
        '2' {
            Configure-WinRMClient
            break
        }
        '3' {
            Configure-WinRMServer
            break
        }
        '4' {
            Configure-AWSSpecificSettings
            break
        }
        '5' {
            Configure-Firewall
            break
        }
        '6' {
            SetupAutomationUser
            break
        }
        '7' {
            $global:NewCertificate = $null
            $global:serverIP = Read-Host "Enter Servers IP address for WinRM"
            Manage-Certificate -IPAddress $serverIP
            break
        }
        '8' {
            Configure-Winrm
            break
        }
        '9' {
            Delete-WinrmListeners
            break
        }
        '10' {
            Get-Certificates
            break
        }
        '11' {
           $thumbprintToDelete = Read-Host "Enter the certificate thumbprint to delete"
	   Delete-Certificate -Thumbprint $thumbprintToDelete 
           break
        }
        '12'{
            Get-WinrmConfig
       	    break
        }
         '13'{
            Check-WinrmListeners
       	    break
        }
        '14'{
            User-PermissionGroup
       	    break
        }
        '15'{
            Write-Host "Example: Remote Management Users / Administrators / Remote Desktop Users"
            $groupToQuery = Read-Host "Enter the name of the group you want to query"
            Get-GroupMembers -GroupName $groupToQuery
            break
        }
        '16' {
            Get-LocalUsers
            break
            }
        '17' {
            Add-DynamicLocalGroupMember
	    break
        }
        'Q' {
            return
        }
    }
    pause
} until ($input -eq 'Q')
