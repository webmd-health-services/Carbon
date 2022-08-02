function Get-CCimClass
{
    <#
    .SYNOPSIS
    Calls Get-CimClass, with a fallback to Get-WmiObject.

    .DESCRIPTION
    The `Get-CCimClass` function calls PowerShell's `Get-CimClass` cmdlet. If CIM isn't available, calls `Get-WmiObject` instead.

    .EXAMPLE
    Get-CCimClass -Class 'Win32_OperatingSystem'

    Demonstrates how to use `Get-CCimClass`. In this example, the function will call `Get-CimClass -ClassName 'Win32_OperatingSystem'`, except when that cmdlet doesn't exist, when it calls `Get-WmiObject -Class 'Win32_OperatingSystem' -List`.
    #>

    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]        
        [String] $Class
    )

    $useCim = Test-CCimAvailable

    if( $useCim )
    {
        Get-CimClass -ClassName $Class
    }
    else
    {
        Get-WmiObject -Class $Class -List
    }
}