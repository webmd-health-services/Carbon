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

function Get-FileShare
{
    <#
    .SYNOPSIS
    Gets the file/SMB shares on the local computer.

    .DESCRIPTION
    The `Get-FileShare` function uses WMI to get the file/SMB shares on the current/local computer. The returned objects are `Win32_Share` WMI objects.

    Use the `Name` paramter to get a specific file share by its name. If a share with the given name doesn't exist, an error is written and nothing is returned.
    
    The `Name` parameter supports wildcards. If you're using wildcards to find a share, and no shares are found, no error is written and nothing is returned.

    `Get-FileShare` was added in Carbon 2.0.

    .LINK
    https://msdn.microsoft.com/en-us/library/aa394435.aspx

    .LINK
    Get-FileSharePermission

    .LINK
    Install-FileShare

    .LINK
    Test-FileShare

    .LINK
    Uninstall-FileShare

    .EXAMPLE
    Get-FileShare

    Demonstrates how to get all the file shares on the local computer.

    .EXAMPLE
    Get-FileShare -Name 'Build'

    Demonstrates how to get a specific file share.

    .EXAMPLE
    Get-FileShare -Name 'Carbon*'

    Demonstrates that you can use wildcards to find all shares that match a wildcard pattern.
    #>
    [CmdletBinding()]
    param(
        [string]
        # The name of a specific share to retrieve. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $filter = '(Type = 0 or Type = 2147483648)'
    $wildcardSearch = [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name)
    if( $Name -and -not $wildcardSearch)
    {
        $filter = '{0} and Name = ''{1}''' -f $filter,$Name
    }

    $shares = Get-WmiObject -Class 'Win32_Share' -Filter $filter |
                    Where-Object { 
                        if( -not $wildcardSearch )
                        {
                            return $true
                        }

                        return $_.Name -like $Name
                    }
    
    if( $Name -and -not $shares -and -not $wildcardSearch )
    {
        Write-Error ('Share ''{0}'' not found.' -f $Name) -ErrorAction $ErrorActionPreference
    }

    $shares
}

