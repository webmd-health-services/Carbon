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

function Get-IisConfigurationSection
{
    <#
    .SYNOPSIS
    Gets a Microsoft.Web.Adminisration configuration section for a given site and path.
    
    .DESCRIPTION
    Uses the Microsoft.Web.Administration API to get a `Microsoft.Web.Administration.ConfigurationSection`.
    
    .OUTPUTS
    Microsoft.Web.Administration.ConfigurationSection.
    
    .EXAMPLE
    Get-IisConfigurationSection -SiteName Peanuts -Path Doghouse -Path 'system.webServer/security/authentication/anonymousAuthentication'

    Returns a configuration section which represents the Peanuts site's Doghouse path's anonymous authentication settings.    
    #>
    [CmdletBinding(DefaultParameterSetName='Global')]
    [OutputType([Microsoft.Web.Administration.ConfigurationSection])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
        [string]
        # The site where anonymous authentication should be set.
        $SiteName,
        
        [Parameter(ParameterSetName='ForSite')]
        [Alias('Path')]
        [string]
        # The optional site path whose configuration should be returned.
        $VirtualPath = '',
        
        [Parameter(Mandatory=$true,ParameterSetName='ForSite')]
        [Parameter(Mandatory=$true,ParameterSetName='Global')]
        [string]
        # The path to the configuration section to return.
        $SectionPath,
        
        [Type]
        # The type of object to return.  Optional.
        $Type = [Microsoft.Web.Administration.ConfigurationSection]
    )
    
    $mgr = New-Object 'Microsoft.Web.Administration.ServerManager'
    $config = $mgr.GetApplicationHostConfiguration()
    
    $section = $null
    try
    {
        if( $PSCmdlet.ParameterSetName -eq 'ForSite' )
        {
            $qualifier = Join-IisVirtualPath $SiteName $VirtualPath
            $section = $config.GetSection( $SectionPath, $Type, $qualifier )
        }
        else
        {
            $section = $config.GetSection( $SectionPath, $Type )
            $qualifier = ''
        }
    }
    catch
    {
    }
        
    if( $section )
    {
        $section | Add-IisServerManagerMember -ServerManager $mgr -PassThru
    }
    else
    {
        Write-Error ('IIS:{0}: configuration section {1} not found.' -f $qualifier,$SectionPath)
        return
    }
}