Function Get-ExchangeOnlineCalendarPermission {
    <#
        .SYNOPSIS
        Get Exchange Online calendar permission

        .DESCRIPTION
        This function will get the Exchange Online calender permissions for specific mailboxes.
        If no parameter is set, every mailbox will bi included.

        .PARAMETER Mailbox
        Specific mailbox

        .INPUTS
        System.String[]

        .OUTPUTS
        System.Object[]

        .EXAMPLE
        Get-ExchangeOnlineCalendarPermission -Mailbox user1@domain.ch,user2.domain.ch

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#get-exchangeonlinecalendarpermission
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Object with mailbox"
        )]
        $Mailbox
    )
    Begin {
        #Check if exchangeonline connection is established
        try {
            $null = Get-EXOMailbox -ResultSize 1 -ErrorAction Stop    
        }
        catch {
            Throw "You need to connect to exchange online to use this function."
        }
    }
    Process {

        Write-Verbose "Get mailbox"
        if ($null -eq $Mailbox) {
            $Mailbox = Get-Exomailbox -ResultSize unlimited
        }

        Write-Verbose "Get mailbox permission"
        $calendarpermission = @()
        $Mailbox | ForEach-Object {
            $identity = $_.primarysmtpaddress
            $language = (Get-MailboxRegionalConfiguration -Identity $identity).Language.Name
            if ($language -like "de-*"){
                $calendarpermission += Get-EXOMailboxFolderPermission -Identity "${identity}:\kalender"
            }elseif ($language -like "en-*"){
                $calendarpermission += Get-EXOMailboxFolderPermission -Identity "${identity}:\calendar"
            }elseif ($null -eq $language){
                Write-Warning "Language is not set for Mailbox $Identity"
            }else {
                Throw "$language is not supported!"
            }
        }

        #Join-Table
        $OutputObject += Join-Table -Row $Mailbox -RowTitle "PrimarySmtpAddress" -RowIdentifier "PrimarySmtpAddress" -Column $calendarpermission -ColumnTitle "Identity" -ColumnIdentifier "User" -FieldValue "AccessRights"
    }
    End {
        return $OutputObject
    }
}