
function Test-CFirewallStatefulFtp
{
    <#
    .SYNOPSIS
    Tests if the firewall's `StatefulFtp` setting is enabled.

    .DESCRIPTION
    Returns `True` if the firewall's `StatefulFtp` setting is enabled, `False` otherwise.

    If the firewall isn't configurable, writes an error and returns nothing, which will probably be interpreted by your script as `False`.  Can't help you there.  At least you'll get an error message.

    .OUTPUTS
    System.Boolean.

    .LINK
    Assert-CFirewallConfigurable

    .EXAMPLE
    Test-CFirewallStatefulFtp
    
    Returns `True` if the firewall's `StatefulFtp` setting is enabled, `False` otherwise.
    #>
    [CmdletBinding()]
    param(
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Assert-CFirewallConfigurable) )
    {
        return
    }
    
    $output = netsh advfirewall show global StatefulFtp
    $line = $output[3]
    return $line -match 'Enable'
}

