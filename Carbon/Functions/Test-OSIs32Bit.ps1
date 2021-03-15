
function Test-COSIs32Bit
{
    <#
    .SYNOPSIS
    Tests if the current operating system is 32-bit.
    
    .DESCRIPTION
    Regardless of the bitness of the currently running process, returns `True` if the current OS is a 32-bit OS.
    
    .OUTPUTS
    System.Boolean.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.environment.is64bitoperatingsystem.aspx
    
    .EXAMPLE
    Test-COSIs32Bit
    
    Returns `True` if the current operating system is 32-bit, and `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [switch]$NoWarn
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        $msg = 'Carbon''s "Test-COSIs32Bit" function is OBSOLETE and will be removed in the next major version of ' +
               'Carbon. Use the new "Test-COperatingSystem" function in the new Carbon.Core module instead.'
        Write-CWarningOnce -Message $msg
    }

    return -not (Test-COSIs64Bit -NoWarn)
}

