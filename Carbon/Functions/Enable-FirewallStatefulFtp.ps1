
function Enable-CFirewallStatefulFtp
{
    <#
    .SYNOPSIS
    Enables the `StatefulFtp` Windows firewall setting.

    .DESCRIPTION
    Uses the `netsh` command to enable the `StatefulFtp` Windows firewall setting.

    If the firewall isn't configurable, writes an error and returns without making any changes.

    .LINK
    Assert-CFirewallConfigurable

    .EXAMPLE
    Enable-CFirewallStatefulFtp
    
    Enables the `StatefulFtp` Windows firewall setting.
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
    
    Invoke-ConsoleCommand -Target 'firewall' -Action 'enable stateful FTP' -ScriptBlock {
        netsh advfirewall set global StatefulFtp enable
    }
}

