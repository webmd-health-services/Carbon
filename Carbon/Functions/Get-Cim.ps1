
function Get-Cim
{
    <#
    .SYNOPSIS
    Gets the CIM instance of a class or information about the avaialble classes.

    .DESCRIPTION
    Get-WmiObject has been deprecated since PowerShell 6 and Get-CimInstance is the new method to use. This function will determine
    which method to use based on the version of PowerShell. Currently only accepting $Class, $Filter, $List, and $Query parameters
    as these are the ones being used in Carbon. More parameters can be added if needed.

    .EXAMPLE
    Get-Cim -ClassName 'Win32_OperatingSystem'

    Gets the instance for Win32_OperatingSystem class.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]        
        [String] $Class,

        [String] $Filter,

        [Switch] $List,

        [String] $Query
    )
    $IsPSCore = $PSVersionTable.PSEdition -eq 'Core'
    $optionalArgs = @{ }

    if( $Filter )
    {
        $optionalArgs['Filter'] = $Filter
    }

    if( $List -and -not $IsPSCore )
    {
        $optionalArgs['List'] = $List
    }

    if( $Query )
    {
        $optionalArgs['Query'] = $Query
    }
    
    if( $IsPSCore )
    {
        if( $List )
        {
            Get-CimClass -ClassName $Class
        }
        else
        {
            Get-CimInstance -ClassName $Class @optionalArgs
        }
    }
    else
    {
        Get-WmiObject -Class $Class @optionalArgs
    }
}