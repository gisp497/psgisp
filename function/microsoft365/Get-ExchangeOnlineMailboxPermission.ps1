Function Get-ExchangeOnlineMailboxPermission {
    <#
        .SYNOPSIS
        Get Exchange Online permission

        .DESCRIPTION
        This function will get the Exchange Online permissions for specific mailboxes.
        If no parameter is set, every mailbox will bi included.

        .PARAMETER Mailbox
        Specific mailbox

        .INPUTS
        System.String[]

        .OUTPUTS
        System.Object[]

        .EXAMPLE
        Get-ExchangeOnlineMailboxPermission -Mailbox user1@domain.ch,user2.domain.ch

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#get-exchangeonlinemailboxpermission
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Mailbox Name"
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
        $mailboxpermission = $Mailbox | Get-EXOMailboxPermission

        
        Write-Verbose "Join-Table"
        $OutputObject += Join-Table -Row $Mailbox -RowTitle "PrimarySmtpAddress" -RowIdentifier "MemberOf" -Column $mailboxpermission -ColumnTitle "Identity" -ColumnIdentifier "User" -FieldValue "AccessRights"
    }
    End {
        #return Output
        return $OutputObject
    }
}