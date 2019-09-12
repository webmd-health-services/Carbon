
function Clear-CTrustedHost
{
    <#
    .SYNOPSIS
    Removes all entries from PowerShell trusted hosts list.
    
    .DESCRIPTION
    The `Add-CTrustedHost` function adds new entries to the trusted hosts list.  `Set-CTrustedHost` sets it to a new list.  This function clears out the trusted hosts list completely.  After you run it, you won't be able to connect to any computers until you add them to the trusted hosts list.
    
    .LINK
    Add-CTrustedHost
    
    .LINK
    Set-CTrustedHost

    .EXAMPLE
    Clear-CTrustedHost
    
    Clears everything from the trusted hosts list.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $pscmdlet.ShouldProcess( 'trusted hosts', 'clear' ) )
    {
        Set-Item $TrustedHostsPath -Value '' -Force
    }

}

Set-Alias -Name 'Clear-TrustedHosts' -Value 'Clear-CTrustedHost'
