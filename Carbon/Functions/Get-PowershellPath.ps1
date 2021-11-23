
function Get-CPowershellPath
{
    <#
    .SYNOPSIS
    Gets the path to powershell.exe.

    .DESCRIPTION
    Returns the path to the powershell.exe binary for the machine's default architecture (i.e. x86 or x64).  If you're on a x64 machine and want to get the path to x86 PowerShell, set the `x86` switch.
    
    Here are the possible combinations of operating system, PowerShell, and desired path architectures, and the path they map to.
    
        +-----+-----+------+--------------------------------------------------------------+
        | OS  | PS  | Path | Result                                                       |
        +-----+-----+------+--------------------------------------------------------------+
        | x64 | x64 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x64 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x64 | x86 | x64  | $env:windir\sysnative\Windows PowerShell\v1.0\powershell.exe |
        | x64 | x86 | x86  | $env:windir\SysWOW64\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x64  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        | x86 | x86 | x86  | $env:windir\System32\Windows PowerShell\v1.0\powershell.exe  |
        +-----+-----+------+--------------------------------------------------------------+
    
    .EXAMPLE
    Get-CPowerShellPath

    Returns the path to the version of PowerShell that matches the computer's architecture (i.e. x86 or x64).

    .EXAMPLE
    Get-CPowerShellPath -x86

    Returns the path to the x86 version of PowerShell.
    #>
    [CmdletBinding()]
    param(
        # Gets the path to 32-bit PowerShell.
        [switch]$x86,

        [switch]$NoWarn
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not $NoWarn )
    {
        Write-CRefactoredCommandWarning -CommandName $MyInvocation.MyCommand.Name -ModuleName 'Carbon.Core'
    }

    $psPath = $PSHOME
    if( (Test-COSIs64Bit -NoWarn) )
    {
        if( (Test-CPowerShellIs64Bit -NoWarn) )
        {
            if( $x86 )
            {
                # x64 OS, x64 PS, want x86 path
                $psPath = $PSHOME -replace 'System32','SysWOW64'
            }
        }
        else
        {
            if( -not $x86 )
            {
                # x64 OS, x32 PS, want x64 path
                $psPath = $PSHome -replace 'SysWOW64','sysnative'
            }
        }
    }
    else
    {
        # x86 OS, no SysWOW64, everything is in $PSHOME
        $psPath = $PSHOME
    }
    
    Join-Path $psPath powershell.exe
}

