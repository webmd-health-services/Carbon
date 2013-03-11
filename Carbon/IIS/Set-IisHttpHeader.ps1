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
    Set-IisHttpHeader -SiteName 'SopwithCamel' -Path 'Engine' -Name 'X-Powered-By' -Value 'Root Beer'
    
    Sets or creates the `SopwithCamel` website's `Engine` sub-directory's `X-Powered-By` HTTP header to the value `Root Beer`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website where the HTTP header should be set/created.
        $SiteName,
        
        [string]
        # The optional path under `SiteName` where the HTTP header should be set/created.
        $Path = '',
        
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
                                                -Path $Path `
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
    
    if( $pscmdlet.ShouldProcess( ('{0}/{1}' -f $SiteName,$Path), ('{0} HTTP header {1}' -f $action,$Name) ) )
    {
        Write-Host ('IIS:{0}/{1}: {2} HTTP Header {3}: {4}' -f $SiteName,$Path,$action,$Name,$Value)
        $httpProtocol.CommitChanges()
    }
}
