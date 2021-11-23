
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
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name `
                                        -ModuleName 'Carbon.Core' `
                                        -NewCommandName 'Test-COperatingSystem'
    }

    return -not (Test-COSIs64Bit -NoWarn)
}

