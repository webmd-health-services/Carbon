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

function Get-IisHttpRedirect
{
    <#
    .SYNOPSIS
    Gets the HTTP redirect settings for a website or virtual directory/application under a website.
    
    .DESCRIPTION
    Returns a `Carbon.Iis.HttpRedirectConfigurationSection` object for the given HTTP redirect settings.  The object contains the following properties:
    
     * Enabled - `True` if the redirect is enabled, `False` otherwise.
     * Destination - The URL where requests are directed to.
     * HttpResponseCode - The HTTP status code sent to the browser for the redirect.
     * ExactDestination - `True` if redirects are to destination, regardless of the request path.  This will send all requests to `Destination`.
     * ChildOnly - `True` if redirects are only to content in the destination directory (not subdirectories).
	 
    .LINK
    http://www.iis.net/configreference/system.webserver/httpredirect
     
    .OUTPUTS
    Carbon.Iis.HttpRedirectConfigurationSection.
     
    .EXAMPLE
    Get-IisHttpRedirect -SiteName ExampleWebsite 
    
    Gets the redirect settings for ExampleWebsite.
    
    .EXAMPLE
    Get-IisHttpRedirect -SiteName ExampleWebsite -Path MyVirtualDirectory
    
    Gets the redirect settings for the MyVirtualDirectory virtual directory under ExampleWebsite.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site's whose HTTP redirect settings will be retrieved.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path to a sub-directory under `SiteName` whose settings to return.
        $VirtualPath = ''
    )
    
    Get-IisConfigurationSection -SiteName $SiteName `
                                -VirtualPath $VirtualPath `
                                -SectionPath 'system.webServer/httpRedirect' `
                                -Type ([Carbon.Iis.HttpRedirectConfigurationSection])
}
