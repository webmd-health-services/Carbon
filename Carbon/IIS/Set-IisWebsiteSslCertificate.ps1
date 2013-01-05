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

function Set-IisWebsiteSslCertificate
{
    <#
    .SYNOPSIS
    Sets a website's SSL certificate.

    .DESCRIPTION
    SSL won't work on a website if an SSL certificate hasn't been bound to all the IP addresses it's listening on.  This function binds a certificate to all a website's IP addresses.  Make sure you call this method *after* you create a website's bindings.  Any previous SSL bindings on those IP addresses are deleted.

    .EXAMPLE
    Set-IisWebsiteSslCertificate -SiteName Peanuts -Thumbprint 'a909502dd82ae41433e6f83886b00d4277a32a7b' -ApplicationID $PeanutsAppID

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
    
    $site = Get-IisWebsite -SiteName $SiteName
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
        Set-SslCertificateBinding @installArgs -ApplicationID $ApplicationID -Thumbprint $Thumbprint
    }
}
