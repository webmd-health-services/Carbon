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

function Test-User
{
    <#
    .SYNOPSIS
    Checks if a *local* user account exists.

    .DESCRIPTION
    Uses WMI to check if a *local* user account exists.  Returns `True` if the *local* account exists, or `False` if it doesn't.

    .EXAMPLE
    Test-User -Username HSolo

    Checks if the HSolo *local* account exists.  Returns `True` if it does, `False` if it doesn't or its encased in carbonite.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username of the *local* account to check
        $Username
    )

    $user = Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)' and Name='$Username'"
    return ($user -ne $null)

}
