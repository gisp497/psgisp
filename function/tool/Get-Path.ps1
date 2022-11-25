Function Get-Path {
    <#
        .SYNOPSIS
        short description

        .DESCRIPTION
        long description

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
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "help message"
        )]
        [string]$RootFolder = [Environment]::GetFolderPath('Desktop'),
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "help message"
        )]
        [string]$Description = 'Select Folder or File'
    )
    Begin {
        #load assembly
        [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
    }
    Process {
        #create object
        $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
        
        #set root folder
        $OpenFileDialog.initialDirectory = $RootFolder
        
        #remove filter
        $OpenFileDialog.filter = "All files (*.*)| *.*"
        
        #set windows title
        $OpenFileDialog.Title = $Description
        
        #show window
        $OpenFileDialog.ShowDialog() | Out-Null
    }
    End {
        #output value
        return $OpenFileDialog.filename
    }
}