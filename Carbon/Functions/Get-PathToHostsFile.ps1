
function Get-CPathToHostsFile
{
    <#
    .SYNOPSIS
    Gets the path to this computer's hosts file.
    
    .DESCRIPTION
    This is a convenience method so you don't have to have the path to the hosts file hard-coded in your scripts.
    
    .EXAMPLE
    Get-CPathToHostsFile
    
    Returns `C:\Windows\system32\drivers\etc\hosts`.  Uses the environment variable to find the root to the Windows directory.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    return Join-Path $env:windir system32\drivers\etc\hosts
}

