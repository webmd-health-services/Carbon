
function Set-CTrustedHost
{
    <#
    .SYNOPSIS
    Sets the current computer's trusted hosts list.

    .DESCRIPTION
    Clears the current trusted hosts list, and sets it to contain only the entries given by the `Entries` parameter.
    
    To clear the trusted hosts list, use `Clear-CTrustedHost`.
    
    .LINK
    Clear-CTrustedHost

    .EXAMPLE
    Set-CTrustedHost -Entry example.com,api.example.com,docs.example.com

    Sets the trusted hosts list to contain just the values `example.com`, `api.example.com`, and `docs.example.com`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # An array of trusted host entries.
		[Alias("Entries")]
        $Entry
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $value = $Entry -join ','
    if( $pscmdlet.ShouldProcess( 'trusted hosts', 'set' ) )
    {
        Set-Item $TrustedHostsPath -Value $Value -Force
    }
}

Set-Alias -Name 'Set-TrustedHosts' -Value 'Set-CTrustedHost'

