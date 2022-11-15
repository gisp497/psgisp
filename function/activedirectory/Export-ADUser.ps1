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
        Import-ADUser -UserObject $userobject

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
        #Install ActiveDirectory module
        try {
            Import-Module ActiveDirectory -ErrorAction Stop
        }
        catch {
            Throw "Cant import module ActiveDirectory. Error: $_"
        }
    }
    Process {
        $UserObject | ForEach-Object {
            #Initialize variable
            $properties = @{}

            #Check if properties are empty
            $_.PSObject.Properties | ForEach-Object {
                if("" -ne $_.Value){
                    $properties.Add($_.Name, $_.Value)
                }
            }

            #Create new user and set properties
            Write-Verbose "Create new user and set properties"
            New-ADUser -Name $_.DisplayName -sAmAccountname $_.sAmAccountname
            Set-ADUser -Identity $_.sAmAccountname -Replace $properties
        }
    }
    End {
    }
}
