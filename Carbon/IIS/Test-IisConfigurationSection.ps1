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

function Test-IisConfigurationSection
{
    <#
    .SYNOPSIS
    Tests a configuration section.
    
    .DESCRIPTION
    You can test if a configuration section exists or wheter it is locked.
    
    .OUTPUTS
    System.Boolean.
    
    .EXAMPLE
    Test-IisConfigurationSection -SectionPath 'system.webServer/I/Do/Not/Exist'
    
    Tests if a configuration section exists.  Returns `False`, because the given configuration section doesn't exist.
    
    .EXAMPLE
    Test-IisConfigurationSection -SectionPath 'system.webServer/cgi' -Locked
    
    Returns `True` if the global CGI section is locked.  Otherwise `False`.
    
    .EXAMPLE
    Test-IisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication' -SiteName `Peanuts` -VirtualPath 'SopwithCamel' -Locked

    Returns `True` if the `Peanuts` website's `SopwithCamel` sub-directory's `basicAuthentication` security authentication section is locked.  Otherwise, returns `False`.
    #>
    [CmdletBinding(DefaultParameterSetName='CheckExists')]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the section to test.
        $SectionPath,
        
        [Parameter()]
        [string]
        # The name of the site whose configuration section to test.  Optional.  The default is the global configuration.
        $SiteName,
        
        [Parameter()]
        [Alias('Path')]
        [string]
        # The optional path under `SiteName` whose configuration section to test.
        $VirtualPath,
        
        [Parameter(Mandatory=$true,ParameterSetName='CheckLocked')]
        [Switch]
        # Test if the configuration section is locked.  
        $Locked
    )
    
    $getArgs = @{
                    SectionPath = $SectionPath;
                }
    if( $SiteName )
    {
        $getArgs.SiteName = $SiteName
    }
    
    if( $VirtualPath )
    {
        $getArgs.VirtualPath = $VirtualPath
    }
    
    $section = Get-IisConfigurationSection @getArgs -ErrorAction SilentlyContinue
    
    if( $pscmdlet.ParameterSetName -eq 'CheckExists' )
    {
        if( $section )
        {
            return $true
        }
        else
        {
            return $false
        }
    }
        
    if( -not $section )
    {
        Write-Error ('IIS:{0}: section {1} not found.' -f (Join-IisVirtualPath $SiteName $VirtualPath),$SectionPath)
        return
    }
    
    if( $pscmdlet.ParameterSetName -eq 'CheckLocked' )
    {
        return $section.OverrideMode -eq 'Deny'
    }
}