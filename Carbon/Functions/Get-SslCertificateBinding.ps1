
function Get-CSslCertificateBinding
{
    <#
    .SYNOPSIS
    Gets the SSL certificate bindings on this computer.
   
    .DESCRIPTION
    Windows binds SSL certificates to an IP addresses/port combination.  This function gets all the SSL bindings on this computer, or a binding for a specific IP/port, or $null if one doesn't exist.  The bindings are returned as `Carbon.Certificates.SslCertificateBinding` objects.
    
    .OUTPUTS
    Carbon.Certificates.SslCertificateBinding.

    .EXAMPLE
    > Get-CSslCertificateBinding
    
    Gets all the SSL certificate bindings on the local computer.

    .EXAMPLE
    > Get-CSslCertificateBinding -IPAddress 42.37.80.47 -Port 443
   
    Gets the SSL certificate bound to 42.37.80.47, port 443.
   
    .EXAMPLE
    > Get-CSslCertificateBinding -Port 443
   
    Gets the default SSL certificate bound to ALL the computer's IP addresses on port 443.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Certificates.SslCertificateBinding])]
    param(
        [IPAddress]
        # The IP address whose certificate(s) to get.  Should be in the form IP:port. Optional.
        $IPAddress,
        
        [UInt16]
        # The port whose certificate(s) to get. Optional.
        $Port
    )
   
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    [Carbon.Certificates.SslCertificateBinding]::GetSslCertificateBindings() |
        Where-Object {
            if( $IPAddress )
            {
                $_.IPAddress -eq $IPAddress
            }
            else
            {
                return $true
            }
        } |
        Where-Object {
            if( $Port )
            {
                $_.Port -eq $Port
            }
            else
            {
                return $true
            }
        }
    
}

Set-Alias -Name 'Get-SslCertificateBindings' -Value 'Get-CSslCertificateBinding'
