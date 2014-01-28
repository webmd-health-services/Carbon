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

function Set-IisHttpRedirect
{
    <#
    .SYNOPSIS
    Turns on HTTP redirect for all or part of a website.

    .DESCRIPTION
    Configures all or part of a website to redirect all requests to another website/URL.  By default, it operates on a specific website.  To configure a directory under a website, set `VirtualPath` to the virtual path of that directory.

    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect#005
	
    .LINK
    http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx

    .EXAMPLE
    Set-IisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-IisHttpRedirect -SiteName Peanuts -VirtualPath Snoopy/DogHouse -Destination 'http://new.peanuts.com'

    Redirects all requests to the `/Snoopy/DogHouse` path on the `Peanuts` website to `http://new.peanuts.com`.

    .EXAMPLE
    Set-IisHttpRedirect -SiteName Peanuts -Destination 'http://new.peanuts.com' -StatusCode 'Temporary'

    Redirects all requests to the `Peanuts` website to `http://new.peanuts.com` with a temporary HTTP status code.  You can also specify `Found` (HTTP 302), or `Permanent` (HTTP 301).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the redirection should be setup.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path where redirection should be setup.
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true)]
        [string]
        # The destination to redirect to.
        $Destination,
        
        [Carbon.Iis.HttpResponseStatus]
        # The HTTP status code to use.  Default is `Found`.  Should be one of `Found` (HTTP 302), `Permanent` (HTTP 301), or `Temporary` (HTTP 307).
        [Alias('StatusCode')]
        $HttpResponseStatus = [Carbon.Iis.HttpResponseStatus]::Found,
        
        [Switch]
        # Redirect all requests to exact destination (instead of relative to destination).  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
        $ExactDestination,
        
        [Switch]
        # Only redirect requests to content in site and/or path, but nothing below it.  I have no idea what this means.  [Maybe TechNet can help.](http://technet.microsoft.com/en-us/library/cc732969(v=WS.10).aspx)
        $ChildOnly
    )
    
    $settings = Get-IisHttpRedirect -SiteName $SiteName -Path $VirtualPath
    $settings.Enabled = $true
    $settings.Destination = $destination
    $settings.HttpResponseStatus = $HttpResponseStatus
    $settings.ExactDestination = $ExactDestination
    $settings.ChildOnly = $ChildOnly
    	
    if( $pscmdlet.ShouldProcess( (Join-IisVirtualPath $SiteName $VirtualPath), "set HTTP redirect settings" ) ) 
    {
        $settings.CommitChanges()
    }
}
