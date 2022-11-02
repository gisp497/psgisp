Function New-AzureADAccess {
    <#
        .SYNOPSIS
        Create Azure AD access

        .DESCRIPTION
        This function will create an ceritifcate based AzureAD access.

        .PARAMETER AzureADDirectoryRole
        AzureADDirectoryRole to access

        .PARAMETER CertLifetime
        Lifetime of certificate in years 

        .INPUTS
        System.String[]
        System.Int[]

        .OUTPUTS
        System.Object[]

        .EXAMPLE
        New-AzureADAccess -AzureADDirectoryRole Global Reader -CertLifetime 2

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#new-azureadaccess
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "AzureADDirectoryRole to access"
            )]
        [string]$AzureADDirectoryRole = "Global Reader",
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Lifetime of certificate in years"
        )]
        [int]$CertLifetime = 5
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
            $null = Get-AzureADTenantDetail -ErrorAction Stop
        }catch{
            Throw "You need to connect to Azure AD to use this function."
        }        
    }
    Process {
        Write-Verbose "create self signed cert"
        $clientdomain = (Get-AzureADCurrentSessionInfo).TenantDomain
        $currentDate = Get-Date
        $endDate = $currentDate.AddYears($certlifetime)
        $notAfter = $endDate.AddYears($certlifetime)
        $thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\my -DnsName $clientdomain -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint
        
        Write-Verbose "get random password and export certificate"
        $password = Get-RandomString -Securestring
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
        $tenant = Get-AzureADTenantDetail

        # Now you can login to Azure PowerShell with your Service Principal and Certificate
        $outputobject = New-Object -TypeName psobject
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Customer" -Value $tenant.DisplayName
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Tenant_ID" -Value $tenant.ObjectId
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Application_ID" -Value $sp.AppId
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Certificate_Thumbprint" -Value $thumb
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Certificate_Password" -Value $password
    }
    End {
        return $outputobject
    }
}
