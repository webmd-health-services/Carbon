
function Clear-CDscLocalResourceCache
{
    <#
    .SYNOPSIS
    Clears the local DSC resource cache.

    .DESCRIPTION
    DSC caches resources. This is painful when developing, since you're constantly updating your resources. This function allows you to clear the DSC resource cache on the local computer. What this function really does, is kill the DSC host process running DSC.

    `Clear-CDscLocalResourceCache` is new in Carbon 2.0.

    .EXAMPLE
    Clear-CDscLocalResourceCache
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-WmiObject msft_providers | 
        Where-Object {$_.provider -like 'dsccore'} | 
        Select-Object -ExpandProperty HostProcessIdentifier | 
        ForEach-Object { Get-Process -ID $_ } | 
        Stop-Process -Force
}
