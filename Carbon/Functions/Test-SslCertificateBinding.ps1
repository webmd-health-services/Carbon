
function Test-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Tests if an SSL certificate binding exists.
	
	.DESCRIPTION
	SSL certificates are bound to IP addresses and ports.  This function tests if one exists on a given IP address/port.
	
	.EXAMPLE
	Test-CSslCertificateBinding -Port 443
	
	Tests if there is a default SSL certificate bound to all a machine's IP addresses on port 443.
	
	.EXAMPLE
	Test-CSslCertificateBinding -IPAddress 10.0.1.1 -Port 443
	
	Tests if there is an SSL certificate bound to IP address 10.0.1.1 on port 443.
	
	.EXAMPLE
	Test-CSslCertificateBinding
	
	Tests if there are any SSL certificates bound to any IP address/port on the machine.
    #>
    [CmdletBinding()]
    param(
        [IPAddress]
        # The IP address to test for an SSL certificate.
        $IPAddress,
        
        [Uint16]
        # The port to test for an SSL certificate.
        $Port
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $getArgs = @{ }
    if( $IPAddress )
    {
        $getArgs.IPAddress = $IPAddress
    }
    
    if( $Port )
    {
        $getArgs.Port = $Port
    }
    
    $binding = Get-CSslCertificateBinding @getArgs
    if( $binding )
    {
        return $True
    }
    else
    {
        return $False
    }
}

