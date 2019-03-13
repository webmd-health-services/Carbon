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

function Test-CGroup
{
    <#
    .SYNOPSIS
    Checks if a *local* group exists.

    .DESCRIPTION
    Uses .NET's AccountManagement API to check if a *local* group exists.  Returns `True` if the *local* account exists, or `False` if it doesn't.

    .OUTPUTS
    System.Boolean

    .LINK
    Get-CGroup

    .LINK
    Install-CGroup

    .LINK
    Uninstall-CGroup

    .EXAMPLE
    Test-CGroup -Name RebelAlliance

    Checks if the `RebelAlliance` *local* group exists.  Returns `True` if it does, `False` if it doesn't.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the *local* group to check.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $group = Get-CGroup -Name $Name -ErrorAction Ignore
    if( $group )
    {
        $group.Dispose()
        return $true
    }
    else
    {
        return $false
    }
}

