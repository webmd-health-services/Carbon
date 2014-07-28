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

function Unlock-IisConfigurationSection
{
    <#
    .SYNOPSIS
    Unlocks a section in the IIS server configuration.

    .DESCRIPTION
    Some sections/areas are locked by IIS, so that websites can't enable those settings, or have their own custom configurations.  This function will unlocks those locked sections.  You have to know the path to the section.  You can see a list of locked sections by running:

        C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?

    .EXAMPLE
    Unlock-IisConfigSection -Name 'system.webServer/cgi'

    Unlocks the CGI section so that websites can configure their own CGI settings.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The path to the section to unlock.  For a list of sections, run
        #
        #     C:\Windows\System32\inetsrv\appcmd.exe unlock config /section:?
        $SectionPath
    )
    
    $SectionPath |
        ForEach-Object {
            $section = Get-IisConfigurationSection -SectionPath $_
            $section.OverrideMode = 'Allow'
            if( $pscmdlet.ShouldProcess( $_, 'unlocking IIS configuration section' ) )
            {
                $section.CommitChanges()
            }
        }
}

