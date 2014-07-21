
function Clear-DscLocalResourceCache
{
    <#
    .SYNOPSIS
    Clears the local DSC resource cache.

    .DESCRIPTION
    DSC caches resources. This is painful when developing, since you're constantly updating your resources. This function allows you to clear the DSC resource cache on the local computer. What this function really does, is kill the DSC host process running DSC.

    .EXAMPLE
    Clear-DscLocalResourceCache
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Get-WmiObject msft_providers | 
        Where-Object {$_.provider -like 'dsccore'} | 
        Select-Object -ExpandProperty HostProcessIdentifier | 
        ForEach-Object { Get-Process -ID $_ } | 
        Stop-Process -Force -Verbose:$VerbosePreference -WhatIf:$WhatIfPreference
}