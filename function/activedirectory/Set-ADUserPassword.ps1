Function Set-ADUserPassword {
        <#
        .SYNOPSIS
        Set password for AD user

        .DESCRIPTION
        This script creates random password and sets them to specific ad users.

        .PARAMETER User
        Ad user to get a new password.

        .PARAMETER PasswordLength
        The length of the new password.

        .INPUTS
        System.String[]
        System.Object[]
        System.Int[]

        .OUTPUTS
        System.Object[]

        .EXAMPLE
        Set-ADUserPassword -User gisp -PasswordLength 12

        .LINK
        <url>
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param (
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="Ad user to get a new password"
        )]
        $User,
        [Parameter(
            Mandatory=$false,
            ValueFromPipeline=$false,
            HelpMessage="Length of the password"
        )]
        [int]$PasswordLength = 24
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

        #create Output Array
        $OutputObject = @()
    }
    Process{
        #Get ADuser
        $user | Get-ADUser | Foreach-Object{
            Write-Verbose "Set the new user password"
            $password = Get-RandomString -Length $PasswordLength -SecureString
            Set-ADAccountPassword -Identity $_ -NewPassword $password -Reset

            #Create psobject
            $credential = New-Object -TypeName System.Management.Automation.PSCredential ($_.SamAccountName, $password)
            
            #Add Object to Array
            $OutputObject += $credential
        }
    }
    End{
        #Return output
        return $OutputObject
    }
}