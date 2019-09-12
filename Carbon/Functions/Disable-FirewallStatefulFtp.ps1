
function Disable-CFirewallStatefulFtp
{
    <#
    .SYNOPSIS
    Disables the `StatefulFtp` Windows firewall setting.

    .DESCRIPTION
    Uses the `netsh` command to disable the `StatefulFtp` Windows firewall setting.

    If the firewall isn't configurable, writes an error and returns without making any changes.

    .LINK
    Assert-CFirewallConfigurable

    .EXAMPLE
    Disable-CFirewallStatefulFtp

    Disables the `StatefulFtp` Windows firewall setting.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Assert-CFirewallConfigurable) )
    {
        return
    }
    
    Invoke-ConsoleCommand -Target 'firewall' `
                          -Action 'disabling stateful FTP' `
                          -ScriptBlock {
        netsh advfirewall set global StatefulFtp disable
    }
}

