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

function Uninstall-FileShare
{
    <#
    .SYNOPSIS
    Uninstalls/removes a file share from the local computer.

    .DESCRIPTION
    The `Uninstall-FileShare` function uses WMI to uninstall/remove a file share from the local computer, if it exists. If the file shares does not exist, no errors are written and nothing happens. The directory on the file system the share points to is not removed.

    .LINK
    Get-FileShare

    .LINK
    Get-FileSharePermission

    .LINK
    Install-SmbShare

    .LINK
    Test-FileShare

    .EXAMPLE
    Uninstall-FileShare -Name 'CarbonShare'

    Demonstrates how to uninstall/remove a share from the local computer. If the share does not exist, `Uninstall-FileShare` silently does nothing (i.e. it doesn't write an error).
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific share to uninstall/delete. Wildcards accepted. If the string contains WMI sensitive characters, you'll need to escape them.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    if( -not (Test-FileShare -Name $Name) )
    {
        return
    }

    Get-FileShare -Name $Name |
        ForEach-Object { 
            if( $PSCmdlet.ShouldProcess( ('{0} ({1})' -f $_.Name,$_.Path), 'delete' ) )
            {
                Write-Verbose ('Deleting file share ''{0}'' (Path: {1}).' -f $_.Name,$_.Path)
                $_.Delete() 
            }
        }
}
