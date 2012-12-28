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

function Get-IisWebsite
{
    <#
    .SYNOPSIS
    Gets details about a website.
    
    .DESCRIPTION
    Returns an object containing the name, ID, bindings, and state of a website:
    
     * Bindings - An array of objects for each of the website's bindings.  Each object contains:
      * Protocol - The protocol of the binding, e.g. http, https.
      * IPAddress - The IP address the site is listening to, or * for all IP addresses.
      * Port - The port the site is listening on.
     * Name - The site's name.
     * ID - The site's ID.
     * State - The site's state, e.g. started, stopped, etc.
     
     .EXAMPLE
     Get-IisWebsite -SiteName 'WebsiteName'
     
     Returns the details for the site named `WebsiteName`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the site to get.
        $SiteName
    )
    
    if( -not (Test-IisWebsite -Name $SiteName) )
    {
        return $null
    }
    $siteXml = [xml] (Invoke-AppCmd list site $SiteName -xml)
    $siteXml = $siteXml.appcmd.SITE
    
    $site = @{ }
    
    $bindingsRaw = $siteXml.bindings -split ','
    $bindings = @()
    foreach( $bindingRaw in $bindingsRaw )
    {
        if( $bindingRaw -notmatch '^(https?)/([^:]*):([^:]*)(:(.*))?$' )
        {
            Write-Error "Unable to parse binding '$bindingRaw' for website '$SiteName'."
            continue
        }
        $binding = @{
                        Protocol = $matches[1];
                        IPAddress = $matches[2];
                        Port = $matches[3];
                    }
        $binding.HostName = ''
        if( $matches.Count -ge 5 )
        {
            $binding.HostName = $matches[5]
        }
        
        $bindings += New-Object PsObject -Property $binding
    }
    $site.Bindings = $bindings
    $site.Name = $siteXml.'SITE.NAME'
    $site.ID = $siteXml.'SITE.ID'
    $site.State = $siteXml.state
    return New-Object PsObject -Property $site
}
