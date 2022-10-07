Function Get-GISPExchangeOnlineMailboxPermission {
    <#
        .SYNOPSIS
        short description

        .DESCRIPTION
        long description

        ------------------------------------------------------------------------------
        _____/\\\\\\\\\\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\___________
        ____/\\\//////////__\/////\\\///____/\\\/////////\\\_\/\\\/////////\\\________
        ____/\\\_________________\/\\\______\//\\\______\///__\/\\\_______\/\\\_______
        ____\/\\\____/\\\\\\\_____\/\\\_______\////\\\_________\/\\\\\\\\\\\\\/_______
        _____\/\\\___\/////\\\_____\/\\\__________\////\\\______\/\\\/////////________
        ______\/\\\_______\/\\\_____\/\\\_____________\////\\\___\/\\\________________
        _______\/\\\_______\/\\\_____\/\\\______/\\\______\//\\\__\/\\\_______________
        ________\//\\\\\\\\\\\\/___/\\\\\\\\\\\_\///\\\\\\\\\\\/___\/\\\______________
        __________\////////////____\///////////____\///////////_____\///______________
        ------------------------------------------------------------------------------
        date: 
        ------------------------------------------------------------------------------
        .PARAMETER <name>
        Description of the parameter

        .INPUTS
        You can pipe the value of the parameter (path) to this function / None

        .OUTPUTS
        System.Object[] / None

        .EXAMPLE
        <command>

        .LINK
        <url>
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Object with mailbox")]
        [Object[]]$mailbox
    )
    Begin {
        Write-Verbose "Check if exchangeonline connection is established"
        if (!(Get-PSSession | Where-Object {$_.Name -match 'ExchangeOnline' -and $_.Availability -eq 'Available'})){
            Throw "You need to connect to exchange online to use this function."
        }

        Write-Verbose "Initialize variable"
        $outputobject = @()

        Write-Verbose "Get mailbox"
        if ($null -eq $mailbox) {
            $mailbox = Get-Exomailbox -ResultSize unlimited
        }

        Write-Verbose "Get mailbox permission"
        $mailboxpermission = $mailbox | Get-EXOMailboxPermission
    }
    Process {
        Write-Verbose ""
        $mailbox | ForEach-Object {
            Write-Verbose "Initialize variable"
            $identity = $_.PrimarySmtpAddress
            $property = New-Object -TypeName psobject

            Write-Verbose "Add identity to object"
            Add-Member -InputObject $property -MemberType NoteProperty -Name 'Identity' -Value $identity

            Write-Verbose "Add every mailbox to object"
            $mailboxpermission | Sort-Object -Property Identity -Unique | ForEach-Object {Add-Member -InputObject $property -MemberType NoteProperty -Name $_.Identity -Value $null}

            Write-Verbose "Add Accessrights to existing object"
            $mailboxpermission | Where-Object {$identity -eq $_.User}| ForEach-Object {Add-Member -InputObject $property -MemberType NoteProperty -Name $_.Identity -Value ([string]$_.AccessRights) -Force}
            
            Write-Verbose "Add object to array"
            $outputobject += $property
        }
    }
    End {
        return $outputobject
    }
}
Function Get-GISPExchangeOnlineMailboxFolderPermission {
    <#
        .SYNOPSIS
        short description

        .DESCRIPTION
        long description

        ------------------------------------------------------------------------------
        _____/\\\\\\\\\\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\___________
        ____/\\\//////////__\/////\\\///____/\\\/////////\\\_\/\\\/////////\\\________
        ____/\\\_________________\/\\\______\//\\\______\///__\/\\\_______\/\\\_______
        ____\/\\\____/\\\\\\\_____\/\\\_______\////\\\_________\/\\\\\\\\\\\\\/_______
        _____\/\\\___\/////\\\_____\/\\\__________\////\\\______\/\\\/////////________
        ______\/\\\_______\/\\\_____\/\\\_____________\////\\\___\/\\\________________
        _______\/\\\_______\/\\\_____\/\\\______/\\\______\//\\\__\/\\\_______________
        ________\//\\\\\\\\\\\\/___/\\\\\\\\\\\_\///\\\\\\\\\\\/___\/\\\______________
        __________\////////////____\///////////____\///////////_____\///______________
        ------------------------------------------------------------------------------
        date: 
        ------------------------------------------------------------------------------
        .PARAMETER <name>
        Description of the parameter

        .INPUTS
        You can pipe the value of the parameter (path) to this function / None

        .OUTPUTS
        System.Object[] / None

        .EXAMPLE
        <command>

        .LINK
        <url>
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Object with mailbox")]
        [Object[]]$mailbox
    )
    Begin {
        Write-Verbose "Check if exchangeonline connection is established"
        if (!(Get-PSSession | Where-Object {$_.Name -match 'ExchangeOnline' -and $_.Availability -eq 'Available'})){
            Throw "You need to connect to exchange online to use this function."
        }
        
        Write-Verbose "Initialize variable"
        $outputobject = @()

        Write-Verbose "Get mailbox"
        if ($null -eq $mailbox) {
            $mailbox = Get-Exomailbox -ResultSize unlimited
        }

        Write-Verbose "Get mailbox permission"
        $calendarpermission = @()
        $mailbox | ForEach-Object {
            $identity = $_.primarysmtpaddress
            $language = Get-MailboxRegionalConfiguration -Identity $identity | Select-Object Language
            if ($language.Language -like "de-*") {
                $calendarpermission += Get-EXOMailboxFolderPermission -Identity "${identity}:\kalender"
            }elseif ($language.Language -like "en-*") {
                $calendarpermission += Get-EXOMailboxFolderPermission -Identity "${identity}:\calendar"
            }else {
                Throw "$language is not supported!"
            }
        }
    }
    Process {
        Write-Verbose ""
        $mailbox | ForEach-Object {
            Write-Verbose "Initialize variable"
            $identity = $_.PrimarySmtpAddress
            $property = New-Object -TypeName psobject

            Write-Verbose "Add identity to object"
            Add-Member -InputObject $property -MemberType NoteProperty -Name 'Identity' -Value $identity

            Write-Verbose "Add every mailbox to object"
            $calendarpermission | Sort-Object -Property Identity -Unique | ForEach-Object {Add-Member -InputObject $property -MemberType NoteProperty -Name $_.Identity -Value $null}

            Write-Verbose "Add Accessrights to existing object"
            $calendarpermission | Where-Object {$identity -eq $_.User}| ForEach-Object {Add-Member -InputObject $property -MemberType NoteProperty -Name $_.Identity -Value ([string]$_.AccessRights) -Force}
            
            Write-Verbose "Add object to array"
            $outputobject += $property
        }
    }
    End {
        return $outputobject
    }
}
Function Set-GISPExchangeOnlinedefaultsettings {
    <#
        .SYNOPSIS
        short description

        .DESCRIPTION
        long description
        
        ------------------------------------------------------------------------------
        _____/\\\\\\\\\\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\___________
        ____/\\\//////////__\/////\\\///____/\\\/////////\\\_\/\\\/////////\\\________
        ____/\\\_________________\/\\\______\//\\\______\///__\/\\\_______\/\\\_______
        ____\/\\\____/\\\\\\\_____\/\\\_______\////\\\_________\/\\\\\\\\\\\\\/_______
        _____\/\\\___\/////\\\_____\/\\\__________\////\\\______\/\\\/////////________
        ______\/\\\_______\/\\\_____\/\\\_____________\////\\\___\/\\\________________
        _______\/\\\_______\/\\\_____\/\\\______/\\\______\//\\\__\/\\\_______________
        ________\//\\\\\\\\\\\\/___/\\\\\\\\\\\_\///\\\\\\\\\\\/___\/\\\______________
        __________\////////////____\///////////____\///////////_____\///______________
        ------------------------------------------------------------------------------
        date: 
        ------------------------------------------------------------------------------
        .PARAMETER <name>
        Description of the parameter

        .INPUTS
        You can pipe the value of the parameter (path) to this function / None

        .OUTPUTS
        Powershell Object / None

        .EXAMPLE
        <command>

        .LINK
        <url>
    #>
    [CmdletBinding()]
    param (
    )
    Begin {
        Write-Verbose "Check if exchangeonline connection is established"
        if (!(Get-PSSession | Where-Object {$_.Name -match 'ExchangeOnline' -and $_.Availability -eq 'Available'})){
            Throw "You need to connect to exchange online to use this function."
        }
    }
    Process {
    Write-Verbose "Enable Organizationconfig"
    Enable-OrganizationCustomization
    
    Write-Verbose "Set default language de-ch"
    Get-Exomailbox | Set-MailboxRegionalConfiguration -Language 2055 -TimeZone "W. Europe Standard Time" -LocalizeDefaultFolderName

    Write-Verbose "Disable FocusedInbox"
    Set-OrganizationConfig -FocusedInboxOn $false
    }
    End {
    }
}
function New-GISPAzureAccess {
    <#
        .SYNOPSIS
        short description

        .DESCRIPTION
        long description

        ------------------------------------------------------------------------------
        _____/\\\\\\\\\\\\__/\\\\\\\\\\\_____/\\\\\\\\\\\____/\\\\\\\\\\\\\___________
        ____/\\\//////////__\/////\\\///____/\\\/////////\\\_\/\\\/////////\\\________
        ____/\\\_________________\/\\\______\//\\\______\///__\/\\\_______\/\\\_______
        ____\/\\\____/\\\\\\\_____\/\\\_______\////\\\_________\/\\\\\\\\\\\\\/_______
        _____\/\\\___\/////\\\_____\/\\\__________\////\\\______\/\\\/////////________
        ______\/\\\_______\/\\\_____\/\\\_____________\////\\\___\/\\\________________
        _______\/\\\_______\/\\\_____\/\\\______/\\\______\//\\\__\/\\\_______________
        ________\//\\\\\\\\\\\\/___/\\\\\\\\\\\_\///\\\\\\\\\\\/___\/\\\______________
        __________\////////////____\///////////____\///////////_____\///______________
        ------------------------------------------------------------------------------
        date: 
        ------------------------------------------------------------------------------
        .PARAMETER <name>
        Description of the parameter

        .INPUTS
        You can pipe the value of the parameter (path) to this function / None

        .OUTPUTS
        System.Object[] / None

        .EXAMPLE
        <command>

        .LINK
        <url>
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "azureaddirectoryrole")]
        [string]$azureaddirectoryrole = "Global Reader",
        [Parameter(Position=1,
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "lifetime of certificate")]
        [int]$certlifetime = 5
    )
    Begin {
        Write-Verbose "Install AzureAD module"
        if(Get-Module -ListAvailable AzureAD){
            Import-Module AzureAD
        }else{
            Try{
                Install-Module AzureAD
                Import-Module AzureAD
            }catch{
                Throw "Cant import module AzureAD. Error: $_"
            }
        }
        
        Write-Verbose "Connect to Azure AD with credentials"
        try {
            Connect-AzureAD -ErrorAction Stop
        }catch{
            Throw "Cannto connect to Azure AD: $_"
        }        
    }
    Process {
        Write-Verbose "create self signed cert"
        $clientdomain = (Get-AzureADCurrentSessionInfo).TenantDomain
        $currentDate = Get-Date
        $endDate = $currentDate.AddYears($certlifetime)
        $notAfter = $endDate.AddYears($certlifetime)
        $plainpwd = get-gisprandomcharacter
        $thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\my -DnsName $clientdomain -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint
        
        Write-Verbose "get random password and export certificate"
        $password = Get-GISPrandomcharacter -Securestring
        Export-PfxCertificate -cert "cert:\CurrentUser\my\$thumb" -FilePath "$env:USERPROFILE\desktop\azure_access_cert_$clientdomain.pfx" -Password $password

        Write-Verbose "load the certificate"
        $cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("$env:USERPROFILE\desktop\azure_access_cert_$clientdomain.pfx", $password)
        $keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())


        Write-Verbose "create azure application with keyvalue from certificate"
        $identifieruris = 'https://azureaccess.' + $clientdomain
        $azureapplication = "azureaccess"
        $application = New-AzureADApplication -DisplayName $azureapplication -IdentifierUris $identifieruris
        New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier $azureapplication -StartDate $currentDate -EndDate $endDate -Type AsymmetricX509Cert -Usage Verify -Value $keyValue

        Write-Verbose "create the service principal and connect it to the azure application"
        $sp=New-AzureADServicePrincipal -AppId $application.AppId

        # Give the Service Principal Reader access to the current tenant (Get-AzureADDirectoryRole)
        $azureaddirectoryrole = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $azureaddirectoryrole}
        if ($null -eq $azureaddirectoryrole) {
            $azureaddirectoryroletemplate = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq $azureaddirectoryrole}
            Enable-AzureADDirectoryRole -RoleTemplateId $azureaddirectoryroletemplate.ObjectId
            $azureaddirectoryrole = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $azureaddirectoryrole}
        }
        Add-AzureADDirectoryRoleMember -ObjectId $azureaddirectoryrole.ObjectId -RefObjectId $sp.ObjectId

        # Get Tenant Detail
        $tenant=Get-AzureADTenantDetail

        # Now you can login to Azure PowerShell with your Service Principal and Certificate
        $outputobject = New-Object -TypeName psobject
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Customer" -Value $clientdomain
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Tenant_ID" -Value $tenant.ObjectId
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Application_ID" -Value $sp.AppId
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Certificate_Thumbprint" -Value $thumb
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Certificate_Password" -Value $plainpwd
        
        #Disconect AzureAD
        Disconnect-AzureAD
    }
    End {
        return $outputobject
    }
}
