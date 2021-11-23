
function Resolve-CNetPath
{
    <#
    .SYNOPSIS
    OBSOLETE. Will be removed in a future major version of Carbon.
    
    .DESCRIPTION
    OBSOLETE. Will be removed in a future major version of Carbon.
    
    .EXAMPLE
    Write-Error 'OBSOLETE. Will be removed in a future major version of Carbon.'
    
    Demonstates that `Resolve-CNetPath` is obsolete and you shouldn't use it.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-CObsoleteCommandWarning -CommandName $MyInvocation.MyCommand.Name
    
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
