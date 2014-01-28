# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Enable-IisSsl
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
    
    .LINK
    http://support.microsoft.com/?id=907274

    .EXAMPLE
    Enable-IisSsl -Site Peanuts

    Enables SSL on the `Peanuts` website's, making makes SSL connections optional, ignoring client certificates, and making 128-bit SSL optional.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -VirtualPath Snoopy/DogHouse -RequireSsl
    
    Configures the `/Snoopy/DogHouse` directory in the `Peanuts` site to require SSL.  It also turns off any client certificate settings and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -AcceptClientCertificates

    Enables SSL on the `Peanuts` website and configures it to accept client certificates, makes SSL optional, and makes 128-bit SSL optional.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -RequireSsl -RequireClientCertificates

    Enables SSL on the `Peanuts` website and configures it to require SSL and client certificates.  You can't require client certificates without also requiring SSL.

    .EXAMPLE
    Enable-IisSsl -Site Peanuts -Require128BitSsl

    Enables SSL on the `Peanuts` website and require 128-bit SSL.  Also, makes SSL connections optional and ignores client certificates.

    .LINK
    Set-IisWebsiteSslCertificate
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
    
    $flags = @()
    if( $RequireSSL -or $RequireClientCertificates )
    {
        $flags += 'Ssl'
    }
    
    if( $AcceptClientCertificates -or $RequireClientCertificates )
    {
        $flags += 'SslNegotiateCert'
    }
    
    if( $RequireClientCertificates )
    {
        $flags += 'SslRequireCert'
    }
    
    if( $Require128BitSsl )
    {
        $flags += 'Ssl128'
    }
    
    $fullPath = Join-IisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, "enable SSL" ) )
    {
        Invoke-AppCmd set config $fullPath "-section:system.webServer/security/access" "/sslFlags:""$($flags -join ',')""" /commit:apphost
    }
}
