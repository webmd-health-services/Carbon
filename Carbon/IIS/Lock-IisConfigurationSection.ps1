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

function Lock-IisConfigurationSection
{
    <#
    .SYNOPSIS
    Locks an IIS configuration section so that it can't be modified/overridden by individual websites.
    
    .DESCRIPTION
    Locks configuration sections globally so they can't be modified by individual websites.  For a list of section paths, run
    
        C:\Windows\System32\inetsrv\appcmd.exe lock config /section:?
    
    .EXAMPLE
    Lock-IisConfigurationSection -SectionPath 'system.webServer/security/authentication/basicAuthentication'
    
    Locks the `basicAuthentication` configuration so that sites can't override/modify those settings.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The path to the section to lock.  For a list of sections, run
        #
        #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
        $SectionPath
    )

    $SectionPath |
        ForEach-Object {
            $section = Get-IisConfigurationSection -SectionPath $_
            $section.OverrideMode = 'Deny'
            if( $pscmdlet.ShouldProcess( $_, 'locking IIS configuration section' ) )
            {
                $section.CommitChanges()
            }
        }
}