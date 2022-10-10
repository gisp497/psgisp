Function Import-BulkGPO {
    <#
        .SYNOPSIS
        Import multiple GPO

        .DESCRIPTION
        If you export multiple GPOs they want have have the correct and again import, they wan't have the correct GPO Name.
        This function is able to get the correct Name out of the Manifest XML File, which is an automatically created and hidden File.

        .PARAMETER Path
        Path to GPOs

        .INPUTS
        System.String[]

        .OUTPUTS
        None

        .EXAMPLE
        Import-BulkGPO -Path .\Desktop\GPO

        .LINK
        https://github.com/gisp497/psgisp/blob/main/README.md#import-bulkgpo
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Path of the GPO folder"
        )]
        [string]$Path
    )
    Begin{
        Write-Verbose "Install GroupPolicy module"
        if(Get-Module -ListAvailable GroupPolicy){
            Import-Module GroupPolicy
        }else{
            Try{
                Install-WindowsFeature -Name "GPMC"
                Import-Module GroupPolicy
            }catch{
                Throw "Cant import module GroupPolicy. Error: $_"
            }
        }

        Write-Verbose "Test if the GPO path exist."
        try {
            $null = Test-Path $Path -ErrorAction Stop
        }
        catch {
            Throw "The GPO path does not exist. Error: $_"
        }

        Write-Verbose "Test if the manifest.xml file exist."
        try {
            $pathmanifest = $Path.Trim('\') + '\manifest.xml'
            $null = Test-Path $pathmanifest -ErrorAction Stop
        }
        catch {
            Throw "The GPO manisfest does not exist. Error: $_"
        }

        #Create Write-Progress Variable
        $gpocount = (Get-ChildItem -Path $Path | Where-Object Name -ne manifest.xml).count
        $loopcount = 0
    }
    Process{
        #Import GPO loop
        Get-ChildItem -Path $Path -Directory | ForEach-Object{
            Write-Verbose "Create new PSObject"
            $folderid = New-Object PSObject -Property @{id=$_.BaseName}

            Write-Verbose "Get content from manifest."
            [xml]$xml = Get-Content $pathmanifest
            $manifest = Foreach ($x in $xml.Backups.BackupInst) {
                New-Object PSObject -property @{id=$($x.ID | Select-Object -expand "#cdata-section");name=$($x.GPODisplayName | Select-Object -expand "#cdata-section");}
            }
            $gponame = $manifest | Where-Object {$folderid.id -eq $_.id} | Select-Object name

            #Create counter
            $loopcount++
            Write-Progress -Activity 'GPO Import' -PercentComplete (($loopcount / $gpocount) * 100)

            Write-Verbose "Import GPO"
            try {

                $null = Import-GPO -BackupId $_.BaseName -Path $Path -TargetName $gponame.name -CreateIfNeeded -ErrorAction Stop
            }
            catch {
                Throw "The GPOs can't be imported. Error: $_"
            }
        }
    }
    End{
    }
}