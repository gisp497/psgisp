Function Import-PrintGPO {
    <#
        .SYNOPSIS
        Import printer to print gpo

        .DESCRIPTION
        This function can import printer to the print gpo.
        It is important, to add one printer manually to the print gpo!
        Otherwise the function will not work.

        .PARAMETER GPO
        The GPO which will be updated.

        .PARAMETER Printer
        The Shared path of the printer.

        .PARAMETER Action
        Execution of the GPO (create,replace,update)

        .PARAMETER DefaultPrinter
        Sets printer as default printer

        .PARAMETER GroupFilter
        Is used to deploy the printer only to specific groups.

        .INPUTS
        system.string[]

        .OUTPUTS
        none

        .EXAMPLE
        Import-PrintGPO -GPO usr-print-gpo -Printer "\\printserver\printer1","\\printserver\printer2" -Action create -DefaultPrinter -GroupFilter "group1"

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#import-printgpo
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The GPO which will be updated.")]
        [string]$GPO,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The Shared path of the printer.")]
        $Printer,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "GPO action (create, replace or update)")]
        [ValidateSet('create', 'replace','update')]
        [string]$Action = 'update',

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Sets printer as default printer")]
        [switch]$DefaultPrinter,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Is used to deploy the printer only to specific groups.")]
        $GroupFilter = $null
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

        Write-Verbose "Install GroupPolicy module"
        if(Get-Module -ListAvailable GroupPolicy){
            Import-Module GroupPolicy
        }else{
            Try{
                Install-WindowsFeature -Name "GPMC"
            }catch{
                Throw "Cant import module GroupPolicy. Error: $_"
            }
        }

        Write-Verbose "Get date"
        $date = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'

        Write-Verbose "Get gpo action type"
        switch ($Action) {
            create {
                $printgpoimage = 0
                $printgpoaction = 'C'
            }
            replace {
                $printgpoimage = 1
                $printgpoaction = 'R'
            }
            update {
                $printgpoimage = 2
                $printgpoaction = 'U'
            }
        }

        Write-Verbose "Get default printer option"
        if($DefaultPrinter){
            $printgpo_defaultprinter = 1
        }else{
            $printgpo_defaultprinter = 0
        }

        Write-Verbose "Get groupfilter option"
        if($null -ne $GroupFilter){
            try {
                $printgpogroupfilter = '<Filters><FilterGroup bool="AND" not="0" name="' + (Get-ADGroup -Filter 'Name -eq $GroupFilter').Name + '" sid="' + (Get-ADGroup -Filter 'Name -eq $GroupFilter').SID + '" userContext="1" primaryGroup="0" localGroup="0"/></Filters>'
            }
            catch {
                Write-Error "The ad group can't be found."
            }
        }

        Write-Verbose "Get GPO"
        try {
            $printgpo_id = (Get-GPO -DisplayName $GPO -ErrorAction Stop).id
        }
        catch {
            Throw "GPO does not exist. Create GPO and add at least 1 printer to it."
        }
    }

    Process{
        Write-Verbose "Create backup from GPO"
        $gpobackupfolder = $env:APPDATA + '\printgpo'
        try {
            if (Test-Path -Path $gpobackupfolder) {
                Remove-Item -Path $gpobackupfolder -Force -Recurse
            }
            $null = New-Item -Path $gpobackupfolder -ItemType Directory -Force -ErrorAction Stop
            $null = Backup-GPO -Id $printgpo_id -Path $gpobackupfolder -ErrorAction Stop
        }
        catch {
            Throw "The GPO could not be backed up."
        }

        Write-Verbose "Check if printer.xml file exists"
        $printerxml = (Get-ChildItem -Path $gpobackupfolder).FullName + '\DomainSysvol\GPO\User\Preferences\Printers\Printers.xml'
        if(Test-Path -Path $printerxml) {
            $printerxmlcontent = Get-Content $printerxml
        }else {
            Throw "One printer must be already added to the gpo!"
        }

        Write-Verbose "Remove end of printers.xml file"
        $printerxmlcontent = $printerxmlcontent -replace '</Printers>',''
        $printerxmlcontent = $printerxmlcontent | Where-Object {$_.trim() -ne "" }
        $null = Set-Content -Path $printerxml -Value $printerxmlcontent

        Write-Verbose "Add Printers to printers.xml file"
        $Printer | ForEach-Object {
            $uid = New-Guid
            $printername = $_.substring($_.lastindexof("\")+1)
            $printgpo_xmldata = '<SharedPrinter clsid="{9A5E9697-9095-436d-A0EE-4D128FDFBCE5}" name="' + $printername + '" status="' + $printername + '" image="' + $printgpoimage + '" changed="' + $date + '" uid="' + $uid + '" userContext="1" bypassErrors="1"><Properties action="' + $printgpoaction + '" comment="" path="' + $_ + '" location="" default="' + $printgpo_defaultprinter + '" skipLocal="0" deleteAll="0" persistent="0" deleteMaps="0" port=""/>' + $printgpogroupfilter + '</SharedPrinter>'
            $null = Add-Content -Path $printerxml -Value $printgpo_xmldata
        }

        Write-Verbose "Add End of printers.xml file again"
        $null = Add-Content -Path $printerxml -Value '</Printers>'

        Write-Verbose "Restore GPO with new printers"
        try {
            $null = Restore-GPO -Guid $printgpo_id -Path $gpobackupfolder
        }
        catch {
            Throw "The GPO could not be restored. Error: $_"
        }
    }
    End{
        Write-Verbose "Remove old files"
        $null = Remove-Item -Path $gpobackupfolder -Force -Recurse
    }
}