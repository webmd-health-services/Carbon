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

function Set-IisHttpHeader
{
    <#
    .SYNOPSIS
    Sets an HTTP header for a website or a directory under a website.
    
    .DESCRIPTION
    If the HTTP header doesn't exist, it is created.  If a header exists, its value is replaced.
    
    .LINK
    Get-IisHttpHeader
    
    .EXAMPLE
    Set-IisHttpHeader -SiteName 'SopwithCamel' -Name 'X-Flown-By' -Value 'Snoopy'
    
    Sets or creates the `SopwithCamel` website's `X-Flown-By` HTTP header to the value `Snoopy`.
    
    .EXAMPLE
    Set-IisHttpHeader -SiteName 'SopwithCamel' -VirtualPath 'Engine' -Name 'X-Powered-By' -Value 'Root Beer'
    
    Sets or creates the `SopwithCamel` website's `Engine` sub-directory's `X-Powered-By` HTTP header to the value `Root Beer`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website where the HTTP header should be set/created.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path under `SiteName` where the HTTP header should be set/created.
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the HTTP header.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The value of the HTTP header.
        $Value
    )
    
    $httpProtocol = Get-IisConfigurationSection -SiteName $SiteName `
                                                -VirtualPath $VirtualPath `
                                                -SectionPath 'system.webServer/httpProtocol'
    $headers = $httpProtocol.GetCollection('customHeaders') 
    $header = $headers | Where-Object { $_['name'] -eq $Name }
    
    if( $header )
    {
        $action = 'setting'
        $header['name'] = $Name
        $header['value'] = $Value
    }
    else
    {
        $action = 'adding'
        $addElement = $headers.CreateElement( 'add' )
        $addElement['name'] = $Name
        $addElement['value'] = $Value
        [void] $headers.Add( $addElement )
    }
    
    $fullPath = Join-IisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, ('{0} HTTP header {1}' -f $action,$Name) ) )
    {
        $httpProtocol.CommitChanges()
    }
}
