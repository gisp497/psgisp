Function Import-ADUser {
    <#
        .SYNOPSIS
        Imports ADUser

        .DESCRIPTION
        Imports ADUser and their properties, which where saved with the Export-ADUser function.

        .PARAMETER alluser
        Exported PSObject from Export-ADUser function.

        .INPUTS
        Selected.Microsoft.ActiveDirectory.Management.ADUser[]

        .OUTPUTS
        none

        .EXAMPLE
        Import-ADUser -alluser $userprops

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#import-aduser
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position=0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "import object from Export-ADUser")]
        $UserObject
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
    }
    Process {
        $UserObject | ForEach-Object {
            Write-Verbose "Initialize variable"
            $properties = @{}

            Write-Verbose "Check if properties are empty"
            $_.PSObject.Properties | ForEach-Object {
                if($null -ne $_.Value){
                    $properties.Add($_.Name, $_.Value)
                }
            }

            Write-Verbose "Create new user and set properties"
            New-ADUser -Name $_.DisplayName -sAmAccountname $_.sAmAccountname
            Set-ADUser -Identity $_.sAmAccountname -Replace $properties
        }
    }
    End {
    }
}