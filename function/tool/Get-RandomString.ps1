Function Get-RandomString {
    <#
        .SYNOPSIS
        Creates random strings

        .DESCRIPTION
        This functions creates random strings. It is possible to generate Secure Strings.

        .PARAMETER Length
        Determined the length of the string.

        .PARAMETER Securestring
        Can be used, to generate securestrings.

        .INPUTS
        System.Int[]
        System.Switch[]

        .OUTPUTS
        System.String[]
        System.Securestring[]

        .EXAMPLE
        Get-RandomString -Length 23 -SecureString

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#get-randomstring
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "help message")]
        [int]$Length = 24,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Creates Output as secure string")]
        [switch]$SecureString = $false
    )
    Begin {
    }
    Process {
        #Check if Securestring is wanted
        if ($SecureString) {
            $outputobject = -join ((33..126) * 120 | Get-Random -Count $Length | ForEach-Object { [char]$_ }) | ConvertTo-SecureString -AsPlainText -Force
        }else{
            [string]$outputobject = -join ((33..126) * 120 | Get-Random -Count $Length | ForEach-Object { [char]$_ })
        }
        
    }
    End {
        #return value
        return $outputobject
    }
}