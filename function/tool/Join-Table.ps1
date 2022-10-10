Function Join-Table {
    <#
        .SYNOPSIS
        Joins content from 2 seperate object into one

        .DESCRIPTION
        This function can take values from two objects and merge them into one.

        .PARAMETER ROW
        Object wich is used for the rows

        .PARAMETER RowTitle
        Title of the First Column

        .PARAMETER RowIdentifier
        Property to compare

        .PARAMETER Column
        Object wich is used for the columns

        .PARAMETER ColumnTitle
        Object which is used for the columns

        .PARAMETER ColumnIdentifier
        Property to compare

        .PARAMETER FieldValueUnrelated
        Unrelated Fielvalue

        .PARAMETER FieldValue
        FieldValue related to the Column Object

        .INPUTS
        System.String[]
        System.Object[]

        .OUTPUTS
        System.Object[]

        .EXAMPLE
        Join-Table -Row $user -RowTitle "Name" -RowIdentifier "MemberOf" -Column $group -ColumnTitle "Name" -ColumnIdentifier "DistinguishedName" -FieldValue "Name"

        .EXAMPLE
        Join-Table -Row $user -RowTitle "Name" -RowIdentifier "MemberOf" -Column $group -ColumnTitle "Name" -ColumnIdentifier "DistinguishedName" -FieldValueUnrelated $true

        .LINK
        https://github.com/gisp497/psgisp/edit/main/README.md#join-table
    #>
    [CmdletBinding()]
    param (
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Object wich is used for the rows")]
        $Row,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Title of the First Column")]
        $RowTitle,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Property to compare")]
        $RowIdentifier,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Object wich is used for the columns")]
        $Column,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Object which is used for the columns")]
        $ColumnTitle,
        [Parameter(
            Mandatory = $true,
            ValueFromPipeline = $true,
            HelpMessage = "Property to compare")]
        $ColumnIdentifier,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "Unrelated Fielvalue")]
        $FieldValueUnrelated,
        [Parameter(
            Mandatory = $false,
            ValueFromPipeline = $true,
            HelpMessage = "FieldValue related to the Column Object")]
        $FieldValue
    )
    Begin {
        #create array
        $OutputObject = @()
    }
    Process {
        #Loop for every row
        $Row | ForEach-Object {
            #Create Object
            $RowIdentifiervar = $_.$RowIdentifier
            $UserObject = New-Object -TypeName psobject

            #Add RowIdentity to object
            Add-Member -InputObject $UserObject -MemberType NoteProperty -Name $RowTitle -Value $_.$RowTitle

            #Add all Columns to Object without value
            $Column | Sort-Object -Property $ColumnTitle -Unique | ForEach-Object {
                Add-Member -InputObject $UserObject -MemberType NoteProperty -Name $_.$ColumnTitle -Value $null
            }

            if($FieldValue -and $FieldValueUnrelated){
                Throw "Cannt use FieldValue and FieldValueUnrelated Parameter!"
            }elseif($FieldValueUnrelated){
                #Add Accessrights to existing object
                $Column | Where-Object {$RowIdentifiervar -eq $_.$ColumnIdentifier}| ForEach-Object {
                    Add-Member -InputObject $UserObject -MemberType NoteProperty -Name $_.$ColumnTitle -Value $FieldValueUnrelated -Force
                }
            }elseif($FieldValue){
                #Add Accessrights to existing object
                $Column | Where-Object {$RowIdentifiervar -eq $_.$ColumnIdentifier}| ForEach-Object {
                    Add-Member -InputObject $UserObject -MemberType NoteProperty -Name $_.$ColumnTitle -Value $_.$FieldValue -Force
                }
            }else{
                Throw "You need to use the Parameter FielValue or FieldValueUnrelated."
            }
            
            #Add object to array
            $OutputObject += $UserObject
        }
    }
    End {
        #return object 
        return $OutputObject
    }
}