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

function Write-IisVerbose
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]
        # The name of the site.
        $SiteName,

        [string]
        $VirtualPath = '',

        [Parameter(Position=1)]
        [string]
        # The name of the setting.
        $Name,

        [Parameter(Position=2)]
        [string]
        $OldValue = '',

        [Parameter(Position=3)]
        [string]
        $NewValue = ''
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $VirtualPath )
    {
        $SiteName = Join-IisVirtualPath -Path $SiteName -ChildPath $VirtualPath
    }

    Write-Verbose -Message ('[IIS Website] [{0}] {1,-34} {2} -> {3}' -f $SiteName,$Name,$OldValue,$NewValue)
}

