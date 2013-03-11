
function Resolve-NetPath
{
    <#
    .SYNOPSIS
    Returns the path to Windows' `net.exe` command.
    
    .DESCRIPTION
    You can't always assume that `net.exe` is in your path.  Use this function to return the path to `net.exe` regardless of paths in your path environment variable.
    
    .EXAMPLE
    Resolve-NetPath
    
    Returns `C:\Windows\system32\net.exe`.  Usually.
    #>
    [CmdletBinding()]
    param(
    )
    
    $netCmd = Get-Command -CommandType Application -Name net.exe* |
                Where-Object { $_.Name -eq 'net.exe' }
    if( $netCmd )
    {
        return $netCmd.Definition
    }
    
    $netPath = Join-Path $env:WINDIR system32\net.exe
    if( (Test-Path -Path $netPath -PathType Leaf) )
    {
        return $netPath
    }
    
    Write-Error 'net.exe command not found.'
    return $null
}