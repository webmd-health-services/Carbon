
function Set-CIisWebsiteSslCertificate
{
    <#
    .SYNOPSIS
    Sets a website's SSL certificate.

    .DESCRIPTION
    SSL won't work on a website if an SSL certificate hasn't been bound to all the IP addresses it's listening on.  This function binds a certificate to all a website's IP addresses.  Make sure you call this method *after* you create a website's bindings.  Any previous SSL bindings on those IP addresses are deleted.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Set-CIisWebsiteSslCertificate -SiteName Peanuts -Thumbprint 'a909502dd82ae41433e6f83886b00d4277a32a7b' -ApplicationID $PeanutsAppID

    Binds the certificate whose thumbprint is `a909502dd82ae41433e6f83886b00d4277a32a7b` to the `Peanuts` website.  It's a good idea to re-use the same GUID for each distinct application.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose SSL certificate is being set.
        $SiteName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The thumbprint of the SSL certificate to use.
        $Thumbprint,

        [Parameter(Mandatory=$true)]        
        [Guid]
        # A GUID that uniquely identifies this website.  Create your own.
        $ApplicationID
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $site = Get-CIisWebsite -SiteName $SiteName
    if( -not $site ) 
    {
        Write-Error "Unable to find website '$SiteName'."
        return
    }
    
    $site.Bindings | Where-Object { $_.Protocol -eq 'https' } | ForEach-Object {
        $installArgs = @{ }
        if( $_.Endpoint.Address -ne '0.0.0.0' )
        {
            $installArgs.IPAddress = $_.Endpoint.Address.ToString()
        }
        if( $_.Endpoint.Port -ne '*' )
        {
            $installArgs.Port = $_.Endpoint.Port
        }
        Set-CSslCertificateBinding @installArgs -ApplicationID $ApplicationID -Thumbprint $Thumbprint
    }
}

