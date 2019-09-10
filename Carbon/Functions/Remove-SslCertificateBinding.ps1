
function Remove-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Removes an SSL certificate binding.
    
    .DESCRIPTION
    Uses the netsh command line application to remove an SSL certificate binding for an IP/port combination.  If the binding doesn't exist, nothing is changed.
    
    .EXAMPLE
    > Remove-CSslCertificateBinding -IPAddress '45.72.89.57' -Port 443
    
    Removes the SSL certificate bound to IP 45.72.89.57 on port 443.
    
    .EXAMPLE
    > Remove-CSslCertificateBinding 
    
    Removes the default SSL certificate from port 443.  The default certificate is bound to all IP addresses.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [IPAddress]
        # The IP address whose binding to remove.  Default is all IP addresses.
        $IPAddress = '0.0.0.0',
        
        [UInt16]
        # The port of the binding to remove.  Default is port 443.
        $Port = 443
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( -not (Test-CSslCertificateBinding -IPAddress $IPAddress -Port $Port) )
    {
        return
    }
    
    if( $IPAddress.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkV6 )
    {
        $ipPort = '[{0}]:{1}' -f $IPAddress,$Port
    }
    else
    {
        $ipPort = '{0}:{1}' -f $IPAddress,$Port
    }

    Invoke-ConsoleCommand -Target $ipPort `
                          -Action "removing SSL certificate binding" `
                          -ScriptBlock { netsh http delete sslcert ipPort=$ipPort }
}

