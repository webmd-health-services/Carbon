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

function Test-CFileShare
{
    <#
    .SYNOPSIS
    Tests if a file/SMB share exists on the local computer.

    .DESCRIPTION
    The `Test-CFileShare` function uses WMI to check if a file share exists on the local computer. If the share exists, `Test-CFileShare` returns `$true`. Otherwise, it returns `$false`.

    `Test-CFileShare` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Install-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Test-CFileShare -Name 'CarbonShare'

    Demonstrates how to test of a file share exists.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific share to check.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name ('{0}*' -f $Name) |
                Where-Object { $_.Name -eq $Name }

    return ($share -ne $null)
}

