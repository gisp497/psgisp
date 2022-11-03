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
        New-AzureADAccess -Name "test" -Role "Global Reader" -CertLifetime 2

        .LINK
        https://github.com/gisp497/psgisp
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "AzureADDirectoryRole to access"
            )]
        [string]$Role = "Global Reader",
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Name of the New Azure AD Application"
            )]
        [string]$Name = "AzureAccess",
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Lifetime of certificate in years"
        )]
        [int]$CertLifetime = 5
    )
    Begin {
        #Check if AzureAD Module is ready
        try{
            $null = Import-Module AzureAD -ErrorAction Stop
        }catch{
            Throw "Cant import module AzureAD. Error: $_"
        }

        #Connect to Azure AD before using this function
        try {
            $null = Get-AzureADTenantDetail -ErrorAction Stop
        }catch{
            Throw "You need to connect to Azure AD to use this function."
        }

        #Get client domain
        $clientdomain = (Get-AzureADCurrentSessionInfo).TenantDomain

        #Get date for end of cert
        $EndDate = (Get-Date).AddYears($certlifetime)

        #Get Info for azure application
        $identifieruris = 'https://' + $Name + '.' + $clientdomain
        $Name = $Name + '.' + $clientdomain
    }
    Process {
        #create self signed cert
        try {
            $certificate = New-SelfSignedCertificate -CertStoreLocation cert:\CurrentUser\my -DnsName $Name -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $EndDate
            $keyValue = [System.Convert]::ToBase64String($certificate.GetRawCertData())
        }
        catch {
            Throw "Can't create self signed certificate: $_"
        }

        #create azure application with keyvalue from certificate
        try {
            $application = New-AzureADApplication -DisplayName $Name -IdentifierUris $identifieruris
            $null = New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier $Name -EndDate $EndDate -Type AsymmetricX509Cert -Usage Verify -Value $keyValue
        }
        catch {
            Throw "Can't create new Azure AD Application: $_"
        }

        #check if new create application is ready
        do{
            $checkapp = Get-AzureADApplication | Where-Object {$_.ObjectId -eq $application.ObjectId}
        }while ($null -eq $checkapp)
        $null = Remove-Variable checkapp

        #create the service principal and connect it to the azure application
        try {
            $sp=New-AzureADServicePrincipal -AppId $application.AppId -ErrorAction Stop
        }
        catch {
            Throw "Can't create AzureADServicePrincipal: $_"
        }

        # Give the Service Principal Reader access to the current tenant (Get-AzureADDirectoryRole)
        $azureaddirectoryrole = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $Role}
        if ($null -eq $azureaddirectoryrole) {
            $azureaddirectoryroletemplate = Get-AzureADDirectoryRoleTemplate | Where-Object {$_.DisplayName -eq $azureaddirectoryrole}
            $null = Enable-AzureADDirectoryRole -RoleTemplateId $azureaddirectoryroletemplate.ObjectId
            $azureaddirectoryrole = Get-AzureADDirectoryRole | Where-Object {$_.DisplayName -eq $azureaddirectoryrole}
            if ($null -eq $azureaddirectoryrole) {
                Throw "Can't find Azure Directory Role: $Role"
            }
        }
        Start-Sleep -Seconds 1
        try {
            $null = Add-AzureADDirectoryRoleMember -ObjectId $azureaddirectoryrole.ObjectId -RefObjectId $sp.ObjectId -ErrorAction Stop
        }
        catch {
            Throw "Can't Add AzureADDirectoryRoleMember: $_ "
        }

        # Get Tenant Detail
        $tenant = Get-AzureADTenantDetail

        # Now you can login to Azure PowerShell with your Service Principal and Certificate
        $outputobject = New-Object -TypeName psobject
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Customer" -Value $tenant.DisplayName
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Tenant_ID" -Value $tenant.ObjectId
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Application_ID" -Value $sp.AppId
        Add-Member -InputObject $outputobject -MemberType NoteProperty -Name "Certificate_Thumbprint" -Value $certificate.Thumbprint
    }
    End {
        return $outputobject
    }
}