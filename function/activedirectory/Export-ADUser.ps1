Function Export-ADUser {
    <#
        .SYNOPSIS
        Export User
        .DESCRIPTION
        This function exports the most important aduser information into an psobject.
        If more properties where needed, it is possible to add them by using the parameter additionalproperty.
        .PARAMETER user
        User or user array to export
        .PARAMETER additionalproperty
        Can be used to add additional property to the default ones.
        .INPUTS
        System.String[]
        .OUTPUTS
        Selected.Microsoft.ActiveDirectory.Management.ADUser[]
        .EXAMPLE
        Export-ADUser -User "user1","user2" -AdditionalProperty "sid","whenCreated"
        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#export-aduser
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "User or user array to export"
        )]
        $User,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Can be used to add additional property to the default ones."
        )]
        $AdditionalProperty
    )
    Begin {
        Write-Verbose "Install ActiveDirectory module"
        if(Get-Module -ListAvailable ActiveDirectory){
            Import-Module ActiveDirectory
        }else{
            Try{
                Install-WindowsFeature -Name "RSAT-AD-PowerShell"
            }catch{
                Throw "Cant import module ActiveDirectory. Error: $_"
            }
        }

        Write-Verbose "Initialize variable"
        $userproperties = @()
        $allproperties = @("GivenName","sn","DisplayName","Description","mail","telephoneNumber","UserPrincipalName","sAmAccountname","HomeDirectory","HomeDrive")
        if ($null -ne $AdditionalProperty) {
            $AdditionalProperty | ForEach-Object {
                $allproperties += $_
            }
        }
    }
    Process {
        $User | Foreach-Object {
            $userproperties += Get-ADUser -Identity $_ -Properties $allproperties | Select-Object -Property $allproperties
        }
    }
    End {
        return $userproperties
    }
}
