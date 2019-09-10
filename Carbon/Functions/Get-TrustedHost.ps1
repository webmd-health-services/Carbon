
function Get-CTrustedHost
{
    <#
    .SYNOPSIS
    Returns the current computer's trusted hosts list.

    .DESCRIPTION
    PowerShell stores its trusted hosts list as a comma-separated list of hostnames in the `WSMan` drive.  That's not very useful.  This function reads that list, splits it, and returns each item.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Get-CTrustedHost

    If the trusted hosts lists contains `example.com`, `api.example.com`, and `docs.example.com`, returns the following:

        example.com
        api.example.com
        docs.example.com
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $trustedHosts = (Get-Item $TrustedHostsPath -Force).Value 
    if( $trustedHosts )
    {
        return $trustedHosts -split ','
    }
}

Set-Alias -Name 'Get-TrustedHosts' -Value 'Get-CTrustedHost'
