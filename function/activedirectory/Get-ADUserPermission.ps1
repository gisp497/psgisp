Function Get-ADUserPermission {
    <#
        .SYNOPSIS
        Exports user and their groups

        .DESCRIPTION
        This function will export users and their groupmembership.
        By default every user and every group is exported.

        .PARAMETER User
        Users to export

        .PARAMETER Group
        Groups to export

        .INPUTS
        System.String[]
        System.Object[]

        .OUTPUTS
        System.Object[]

        .EXAMPLE
        Get-ADUserPermission

        .EXAMPLE
        Get-ADUserPermission -User user1,user2 -Group group1,group2

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#get-aduserpermission
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$false,
            HelpMessage="AD User to export"
        )]
        $User,
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$false,
            HelpMessage="AD Group to export"
        )]
        $Group
    )
    Begin{
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
    }
    Process{
        #Get AD user
        if($User){
            $User = $User | Get-ADUser -Properties memberof,mail
        }else{
            $User = Get-ADUser -Filter * -Properties memberof,mail
        }
        if ($Group) {
            $Group = $Group | Get-ADGroup
        }else{
            $Group = Get-ADGroup -Filter *
        }

        #Join both Objects
        $OutputObject = Join-Table -Row $User -RowTitle "Name" -RowIdentifier "MemberOf" -Column $Group -ColumnTitle "Name" -ColumnIdentifier "DistinguishedName" -FieldValueUnrelated $true
    }
    End{
        Write-Verbose "Return output"
        return $OutputObject
    }
}