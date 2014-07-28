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

function Enable-IisSecurityAuthentication
{
    <#
    .SYNOPSIS
    Enables anonymous or basic authentication for an entire site or a sub-directory of that site.

    .DESCRIPTION
    By default, enables an authentication type on an entire website.  You can enable an authentication type at a specific path under a website by passing the virtual path (*not* the physical path) to that directory as the value of the `VirtualPath` parameter.

    .LINK
    Disable-IisSecurityAuthentication
    
    .LINK
    Get-IisSecurityAuthentication
    
    .LINK
    Test-IisSecurityAuthentication
    
    .EXAMPLE
    Enable-IisSecurityAuthentication -SiteName Peanuts -Anonymous

    Turns on anonymous authentication for the `Peanuts` website.

    .EXAMPLE
    Enable-IisSecurityAuthentication -SiteName Peanuts Snoopy/DogHouse -Basic

    Turns on anonymous authentication for the `Snoopy/DogHouse` directory under the `Peanuts` website.

    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where anonymous authentication should be set.
        $SiteName,
        
        [Alias('Path')]
        [string]
        # The optional path where anonymous authentication should be set.
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='Anonymous')]
        [Switch]
        # Enable anonymouse authentication.
        $Anonymous,
        
        [Parameter(Mandatory=$true,ParameterSetName='Basic')]
        [Switch]
        # Enable basic authentication.
        $Basic,
        
        [Parameter(Mandatory=$true,ParameterSetName='Windows')]
        [Switch]
        # Enable Windows authentication.
        $Windows
    )
    
    $authType = $pscmdlet.ParameterSetName
    $getArgs = @{ $authType = $true; }
    $authSettings = Get-IisSecurityAuthentication -SiteName $SiteName -VirtualPath $VirtualPath @getArgs
    $authSettings.SetAttributeValue('enabled', 'true')
    
    $fullPath = Join-IisVirtualPath $SiteName $VirtualPath
    if( $pscmdlet.ShouldProcess( $fullPath, ("enable {0}" -f $authType) ) )
    {
        $authSettings.CommitChanges()
    }
}

