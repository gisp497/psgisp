Function Get-GISPrandomcharacter {
    <#
        .SYNOPSIS
        Creates random strings

        .DESCRIPTION
        This functions creates random strings. You can choose characters and the length.

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
        date: 31.08.2022
        ------------------------------------------------------------------------------
        .PARAMETER length
        Determined the length of the string.

        .PARAMETER character
        Determined possible characters of the string.

        .INPUTS
        system.int[]
        system.string[]

        .OUTPUTS
        system.string[]

        .EXAMPLE
        get-gisprandomcharacter -length 12 -character "abcsdfjlk2344"

        .LINK
        https://github.com/gisp497/psgisp
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "help message")]
        [int]$Length = 24,
        [Parameter(Position=1,
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Creates Output as secure string")]
        [switch]$Securestring = $false
    )
    Begin {
    }
    Process {
        if ($securestring) {
            $outputobject = -join ((33..126) * 120 | Get-Random -Count $length | ForEach-Object { [char]$_ }) | ConvertTo-SecureString -AsPlainText -Force
        }else{
            $outputobject = -join ((33..126) * 120 | Get-Random -Count $length | ForEach-Object { [char]$_ })
        }
        
    }
    End {
        return $outputobject
    }
}