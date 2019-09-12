
function Test-CIPAddress
{
    <#
    .SYNOPSIS
    Tests that an IP address is in use on the local computer.

    .DESCRIPTION
    Sometimes its useful to know if an IP address is being used on the local computer.  This function does just that.

    .LINK
    Test-CIPAddress

    .EXAMPLE
    Test-CIPAddress -IPAddress '10.1.2.3'

    Returns `true` if the IP address `10.1.2.3` is being used on the local computer.

    .EXAMPLE
    Test-CIPAddress -IPAddress '::1'

    Demonstrates that you can use IPv6 addresses.

    .EXAMPLE
    Test-CIPAddress -IPAddress ([Net.IPAddress]::Parse('10.5.6.7'))

    Demonstrates that you can use real `System.Net.IPAddress` objects.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        # The IP address to check.
        $IPAddress
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ip = Get-CIPAddress | Where-Object { $_ -eq $IPAddress }
    if( $ip )
    {
        return $true
    }
    else
    {
        return $false
    }
}
