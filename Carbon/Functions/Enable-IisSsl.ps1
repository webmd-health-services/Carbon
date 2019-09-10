
function Enable-CIisSsl
{
    <#
    .SYNOPSIS
    Turns on and configures SSL for a website or part of a website.

    .DESCRIPTION
    This function enables SSL and optionally the site/directory to: 

     * Require SSL (the `RequireSsl` switch)
     * Ignore/accept/require client certificates (the `AcceptClientCertificates` and `RequireClientCertificates` switches).
     * Requiring 128-bit SSL (the `Require128BitSsl` switch).

    By default, this function will enable SSL, make SSL connections optional, ignores client certificates, and not require 128-bit SSL.

    Changing any SSL settings will do you no good if the website doesn't have an SSL binding or doesn't have an SSL certificate.  The configuration will most likely succeed, but won't work in a browser.  So sad.
    
    Beginning with IIS 7.5, the `Require128BitSsl` parameter won't actually change the behavior of a website since [there are no longer 128-bit crypto providers](https://forums.iis.net/p/1163908/1947203.aspx) in versions of Windows running IIS 7.5.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://support.microsoft.com/?id=907274

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts

    Enables SSL on the `Peanuts` website's, making makes SSL connections optional, ignoring client certificates, and making 128-bit SSL optional.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -VirtualPath Snoopy/DogHouse -RequireSsl
    
    Configures the `/Snoopy/DogHouse` directory in the `Peanuts` site to require SSL.  It also turns off any client certificate settings and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -AcceptClientCertificates

    Enables SSL on the `Peanuts` website and configures it to accept client certificates, makes SSL optional, and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -RequireSsl -RequireClientCertificates

    Enables SSL on the `Peanuts` website and configures it to require SSL and client certificates.  You can't require client certificates without also requiring SSL.

    .EXAMPLE
    Enable-CIisSsl -Site Peanuts -Require128BitSsl

    Enables SSL on the `Peanuts` website and require 128-bit SSL.  Also, makes SSL connections optional and ignores client certificates.

    .LINK
    Set-CIisWebsiteSslCertificate
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='IgnoreClientCertificates')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The website whose SSL flags should be modifed.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The path to the folder/virtual directory/application under the website whose SSL flags should be set.
        $VirtualPath = '',
        
        [Parameter(ParameterSetName='IgnoreClientCertificates')]
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Parameter(Mandatory=$true,ParameterSetName='RequireClientCertificates')]
        [Switch]
        # Should SSL be required?
        $RequireSsl,
        
        [Switch]
        # Requires 128-bit SSL.  Only changes IIS behavior in IIS 7.0.
        $Require128BitSsl,
        
        [Parameter(ParameterSetName='AcceptClientCertificates')]
        [Switch]
        # Should client certificates be accepted?
        $AcceptClientCertificates,
        
        [Parameter(Mandatory=$true,ParameterSetName='RequireClientCertificates')]
        [Switch]
        # Should client certificates be required?  Also requires SSL ('RequireSsl` switch).
        $RequireClientCertificates
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $SslFlags_Ssl = 8
    $SslFlags_SslNegotiateCert = 32
    $SslFlags_SslRequireCert = 64
    $SslFlags_SslMapCert = 128
    $SslFlags_Ssl128 = 256

    $intFlag = 0
    $flags = @()
    if( $RequireSSL -or $RequireClientCertificates )
    {
        $flags += 'Ssl'
        $intFlag = $intFlag -bor $SslFlags_Ssl
    }
    
    if( $AcceptClientCertificates -or $RequireClientCertificates )
    {
        $flags += 'SslNegotiateCert'
        $intFlag = $intFlag -bor $SslFlags_SslNegotiateCert
    }
    
    if( $RequireClientCertificates )
    {
        $flags += 'SslRequireCert'
        $intFlag = $intFlag -bor $SslFlags_SslRequireCert
    }
    
    if( $Require128BitSsl )
    {
        $flags += 'Ssl128'
        $intFlag = $intFlag -bor $SslFlags_Ssl128
    }

    $section = Get-CIisConfigurationSection -SiteName $SiteName -VirtualPath $VirtualPath -SectionPath 'system.webServer/security/access'
    if( -not $section )
    {
        return
    }

    $flags = $flags -join ','
    $currentIntFlag = $section['sslFlags']
    $currentFlags = @( )
    if( $currentIntFlag -band $SslFlags_Ssl )
    {
        $currentFlags += 'Ssl'
    }
    if( $currentIntFlag -band $SslFlags_SslNegotiateCert )
    {
        $currentFlags += 'SslNegotiateCert'
    }
    if( $currentIntFlag -band $SslFlags_SslRequireCert )
    {
        $currentFlags += 'SslRequireCert'
    }
    if( $currentIntFlag -band $SslFlags_SslMapCert )
    {
        $currentFlags += 'SslMapCert'
    }
    if( $currentIntFlag -band $SslFlags_Ssl128 )
    {
        $currentFlags += 'Ssl128'
    }

    if( -not $currentFlags )
    {
        $currentFlags += 'None'
    }

    $currentFlags = $currentFlags -join ','


    if( $section['sslFlags'] -ne $intFlag )
    {
        Write-IisVerbose $SiteName 'SslFlags' ('{0} ({1})' -f $currentIntFlag,$currentFlags) ('{0} ({1})' -f $intFlag,$flags) -VirtualPath $VirtualPath
        $section['sslFlags'] = $flags
        if( $pscmdlet.ShouldProcess( (Join-CIisVirtualPath $SiteName $VirtualPath), "enable SSL" ) )
        {
            $section.CommitChanges()
        }
    }
}

