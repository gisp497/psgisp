Function Import-GISPGPO {
    <#
        .SYNOPSIS
        Import GPOs from selected folder

        .DESCRIPTION
        This script will import all backuped GPOs from a specific folder.
        It will also connect the GPO-ID to the GPO-Name. For this function the manifest.xml is necessairy.

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
        date: 03.06.2022
        ------------------------------------------------------------------------------
        .PARAMETER path
        Path of the GPO folder

        .INPUTS
        System.String[]

        .OUTPUTS
        none

        .EXAMPLE
        Import-GISPGPO -path C:\gpo

        .LINK
        https://github.com/gisp497/psgisp
    #>

    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter( Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="Path of the GPO folder")]
        [string]$path
    )
    Begin{
        Write-Verbose "Install GroupPolicy module"
        if(Get-Module -ListAvailable GroupPolicy){
            Import-Module GroupPolicy
        }else{
            Try{
                Install-WindowsFeature –Name "GPMC"
                Import-Module GroupPolicy
            }catch{
                Throw "Cant import module GroupPolicy. Error: $_"
            }
        }

        Write-Verbose "Test if the GPO path exist."
        try {
            $null = Test-Path $path -ErrorAction Stop
        }
        catch {
            Throw "The GPO path does not exist. Error: $_"
        }

        Write-Verbose "Test if the manifest.xml file exist."
        try {
            $pathmanifest = $path.Trim('\') + '\manifest.xml'
            $null = Test-Path $pathmanifest -ErrorAction Stop
        }
        catch {
            Throw "The GPO manisfest does not exist. Error: $_"
        }

        Write-Verbose "Create Write-Progress Variable"
        $gpocount = (Get-ChildItem -Path $path | Where-Object Name -ne manifest.xml).count
        $loopcount = 0
    }
    Process{
        Write-Verbose "Import GPO loop"
        Get-ChildItem -Path $path -Directory | ForEach-Object{
            Write-Verbose "Create new PSObject"
            $folderid = New-Object PSObject -Property @{id=$_.BaseName}

            Write-Verbose "Get content from manifest."
            [xml]$xml = Get-Content $pathmanifest
            $manifest = Foreach ($x in $xml.Backups.BackupInst) {
                New-Object PSObject -property @{id=$($x.ID | Select-Object -expand "#cdata-section");name=$($x.GPODisplayName | Select-Object -expand "#cdata-section");}
            }
            $gponame = $manifest | Where-Object {$folderid.id -eq $_.id} | Select-Object name

            Write-Verbose "Create counter"
            $loopcount++
            Write-Progress -Activity 'GPO Import' -PercentComplete (($loopcount / $gpocount) * 100)

            Write-Verbose "Import GPO"
            try {

                $null = Import-GPO -BackupId $_.BaseName -Path $path -TargetName $gponame.name -CreateIfNeeded -ErrorAction Stop
            }
            catch {
                Throw "The GPOs can't be imported. Error: $_"
            }
        }
    }
    End{
    }
}
Function Get-GISPADuserpermission {
    <#
        .SYNOPSIS
        Exports user and their groups

        .DESCRIPTION
        This Function will export all users and their group into a PSObject

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
        date: 15.06.2022
        ------------------------------------------------------------------------------
        .PARAMETER user
        Users to check the groups

        .PARAMETER adgroupfilter
        Groups from the users which will be checked. Default = all groups

        .INPUTS
        System.String[]

        .OUTPUTS
        PsCustomObject[]

        .EXAMPLE
        get-gispaduserpermission -path C:\users.csv -user gisp

        .LINK
        https://github.com/gisp497/psgisp
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$false,
            ValueFromPipeline=$false,
            HelpMessage="AD User")]
        $user
    )
    Begin{
        Function get-adusergroup{
            param(
                $user
            )
            Write-Verbose "Create properties for the psobject."
            $property = [ordered]@{"Given Name"=$user.GivenName;"Surname"=$user.Surname;"SamAccountName"=$user.SamAccountName;"Mail"=$user.mail}

            Write-Verbose "Check if user has a group membership"
            if($user.memberof){
                Write-Verbose "Get group SID"
                $allgroup = ($user.memberof | Get-ADGroup).SID
            }

            Write-Verbose "Set true or false membership foreach group"
            Get-ADGroup -Filter * | ForEach-Object {
                if($allgroup -eq $_.SID){
                    $property += [ordered]@{$_.Name=$true;}
                }
                else{
                    $property += [ordered]@{$_.Name=$false;}
                }
            }

            Write-Verbose "Create the psobject"
            return [PsCustomObject]$property
        }

        Write-Verbose "Install ActiveDirectory module"
        if(Get-Module -ListAvailable ActiveDirectory){
            Import-Module ActiveDirectory
        }else{
            Try{
                Install-WindowsFeature –Name "RSAT-AD-PowerShell"
            }catch{
                Throw "Cant import module ActiveDirectory. Error: $_"
            }
        }

        Write-Verbose "Initialize variable"
        $outputobject = @()
    }
    Process{
        Write-Verbose "Get AD user"
        if($user){
            $user | Get-ADUser -Properties memberof,mail | Foreach-Object {
                $outputobject += get-adusergroup -user $_
            }
        }else{
            Get-ADUser -Filter * -Properties memberof,mail | Foreach-Object {
                $outputobject += get-adusergroup -user $_
            }
        }
    }
    End{
        Write-Verbose "Return output"
        return $outputobject
    }
}
Function SET-GISPpassword {
    <#
        .SYNOPSIS
        set aduser password

        .DESCRIPTION
        This script creates random password and sets them to specific ad users.

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
        date: 16.06.2022
        ------------------------------------------------------------------------------
        .PARAMETER user
        The AD user which will get a new password. It is possible to pass multiple users (array).

        .PARAMETER passwordlength
        The length of the password the user will get.

        .INPUTS
        system.int64[]
        syste.string[]

        .OUTPUTS
        PsCustomObject[]

        .EXAMPLE
        set-gispbulkpassword -user gisp -passwordlength 12

        .LINK
        https://github.com/gisp497/psgisp
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory=$true,
        ValueFromPipeline=$true,
        HelpMessage="AD User")]
        $user,
        [Parameter(Mandatory=$false,
        ValueFromPipeline=$false,
        HelpMessage="length of the password")]
        [int]$passwordlength = 24
    )
    Begin{
        Write-Verbose "Install ActiveDirectory module"
        if(Get-Module -ListAvailable ActiveDirectory){
            Import-Module ActiveDirectory
        }else{
            Try{
                Install-WindowsFeature –Name "RSAT-AD-PowerShell"
            }catch{
                Throw "Cant import module ActiveDirectory. Error: $_"
            }
        }

        Write-Verbose "create new object"
        $outputobject = @()
    }
    Process{
        Write-Verbose "get ad user"
        $user | Get-ADUser | Foreach-Object{
            Write-Verbose "Set the new user password"
            [securestring]$password = get-gisprandomcharacter -length $passwordlength -securestring
            Set-ADAccountPassword -Identity $_ -NewPassword $password -Reset

            Write-Verbose "Create psobject"
            $credential = New-Object -TypeName System.Management.Automation.PSCredential ($_.SamAccountName, $password)
            
            Write-Verbose "Add Object to Array"
            $outputobject += $credential
        }
    }
    End{
        Write-Verbose "Return output"
        return $outputobject
    }
}
Function Import-GISPprintGPO {
    <#
        .SYNOPSIS
        Import printer to print gpo

        .DESCRIPTION
        This function can import printer to the print gpo. It is important, to add
        manually add one printer to the print gpo! Otherwise the function will not work.

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
        date:15.07.2022
        ------------------------------------------------------------------------------
        .PARAMETER gpo
        The GPO which will be updated.

        .PARAMETER printer
        The Shared path of the printer.

        .PARAMETER action
        Execution of the GPO (create,replace,update)

        .PARAMETER action
        GPO action (create, replace or update)

        .PARAMETER defaultprinter
        Sets printer as default printer

        .PARAMETER groupfilter
        Is used to deploy the printer only to specific groups.

        .INPUTS
        system.string[]

        .OUTPUTS
        none

        .EXAMPLE
        import-gispprintgpo -gpo usr-print-gpo -printer "\\printserver\printer1","\\printserver\printer2" -action create -defaultprinter -groupfilter "group1"

        .LINK
        https://github.com/gisp497/psgisp
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The GPO which will be updated.")]
        [string]$gpo,

        [Parameter(Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "The Shared path of the printer.")]
        $printer,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "GPO action (create, replace or update)")]
        [ValidateSet('create', 'replace','update')]
        [string]$action = 'update',

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Sets printer as default printer")]
        [switch]$defaultprinter,

        [Parameter(Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Is used to deploy the printer only to specific groups.")]
        $groupfilter = $null
    )
    Begin{
        Write-Verbose "Install ActiveDirectory module"
        if(Get-Module -ListAvailable ActiveDirectory){
            Import-Module ActiveDirectory
        }else{
            Try{
                Install-WindowsFeature –Name "RSAT-AD-PowerShell"
            }catch{
                Throw "Cant import module ActiveDirectory. Error: $_"
            }
        }

        Write-Verbose "Install GroupPolicy module"
        if(Get-Module -ListAvailable GroupPolicy){
            Import-Module GroupPolicy
        }else{
            Try{
                Install-WindowsFeature –Name "GPMC"
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
        if($null -ne $groupfilter){
            try {
                $printgpogroupfilter = '<Filters><FilterGroup bool="AND" not="0" name="' + (Get-ADGroup -Filter 'Name -eq $groupfilter').Name + '" sid="' + (Get-ADGroup -Filter 'Name -eq $groupfilter').SID + '" userContext="1" primaryGroup="0" localGroup="0"/></Filters>'
            }
            catch {
                Write-Error "The ad group can't be found."
            }
        }

        Write-Verbose "Get GPO"
        try {
            $printgpo_id = (Get-GPO -DisplayName $gpo -ErrorAction Stop).id
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
        $printer | ForEach-Object {
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
Function Export-GISPADUser {
    <#
        .SYNOPSIS
        Export User

        .DESCRIPTION
        This function exports the most important aduser information into an psobject.
        If more properties where needed, it is possible to add them by using the parameter additionalproperty.

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
        date: 26.08.2022
        ------------------------------------------------------------------------------
        .PARAMETER user
        User or user array to export

        .PARAMETER additionalproperty
        Can be used to add additional property to the default ones.

        .INPUTS
        system.string[]

        .OUTPUTS
        Selected.Microsoft.ActiveDirectory.Management.ADUser[]

        .EXAMPLE
        export-gispaduser -user "user1","user2" -additionalproperty "sid","whenCreated"

        .LINK
        https://github.com/gisp497/psgisp/
    #>
    [CmdletBinding()]
    param (
        [Parameter(Position=0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "User or user array to export")]
        $user,
        [Parameter(Position=1,
            Mandatory = $false,
            ValueFromPipeline = $false,
            HelpMessage = "Can be used to add additional property to the default ones.")]
        $additionalproperty
    )
    Begin {
        Write-Verbose "Check if AD module is installed"
        install-gispmodule -module "activedirectory" -installfeature "RSAT-AD-PowerShell"

        Write-Verbose "Initialize variable"
        $userproperties = @()
        $allproperties = @("GivenName","sn","DisplayName","Description","mail","telephoneNumber","UserPrincipalName","sAmAccountname","HomeDirectory","HomeDrive")
        if ($null -ne $additionalproperty) {
            $additionalproperty | ForEach-Object {
                $allproperties += $_
            }
        }
    }
    Process {
        $user | Foreach-Object {
            $userproperties += Get-ADUser -Identity $_ -Properties $allproperties | Select-Object -Property $allproperties
        }
    }
    End {
        return $userproperties
    }
}
Function Import-GISPADUser {
    <#
        .SYNOPSIS
        Imports ADUser

        .DESCRIPTION
        Imports ADUser and their properties, which where saved with the export-gispaduser function.

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
        date: 31.08.20222
        ------------------------------------------------------------------------------
        .PARAMETER alluser
        Exported PSObject from export-gispaduser function.

        .INPUTS
        Selected.Microsoft.ActiveDirectory.Management.ADUser[]

        .OUTPUTS
        none

        .EXAMPLE
        import-gispaduser -alluser $userprops

        .LINK
        https://github.com/gisp497/psgisp/
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(Position=0,
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "import object from export-gispaduser")]
        $alluser
    )
    Begin {
        Write-Verbose "Check if AD module is installed"
        install-gispmodule -module "activedirectory" -installfeature "RSAT-AD-PowerShell"
    }
    Process {
        $alluser | ForEach-Object {
            Write-Verbose "Initialize variable"
            $properties = @{}

            Write-Verbose "Check if properties are empty"
            $_.PSObject.Properties | ForEach-Object {
                if($_.Value){
                    $properties.Add($_.Name, $_.Value)
                }
            }

            Write-Verbose "Create new user and set properties"
            New-ADUser -Name $_.DisplayName -sAmAccountname $_.sAmAccountname
            Get-ADUser -Identity $_.sAmAccountname | Set-ADUser -Replace $properties
        }
    }
    End {
    }
}