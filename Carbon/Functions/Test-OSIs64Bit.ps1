
function Test-COSIs64Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 64-bit.

    .DESCRIPTION
    Regardless of the bitness of the currently running process, returns `True` if the current OS is a 64-bit OS.

    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx
    
    .EXAMPLE
    Test-COSIs64Bit
    
    Returns `True` if the current operating system is 64-bit, and `False` otherwise.
    #>
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return ([Environment]::Is64BitOperatingSystem)
}

