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

function Test-AdminPrivilege
{
    <#
    .SYNOPSIS
    Checks if the current user is an administrator or has administrative privileges.

    .DESCRIPTION
    Many tools, cmdlets, and APIs require administative privileges.  Use this function to check.  Returns `True` if the current user has administrative privileges, or `False` if he doesn't.  Or she.  Or it.  

    This function handles UAC and computers where UAC is disabled.

    .EXAMPLE
    Test-AdminPrivilege

    Returns `True` if the current user has administrative privileges, or `False` if the user doesn't.
    #>
    [CmdletBinding()]
    param(
    )
    
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Verbose "Checking if current user '$($identity.Name)' has administrative privileges."

    $hasElevatedPermissions = $false
    foreach ( $group in $identity.Groups )
    {
        if ( $group.IsValidTargetType([Security.Principal.SecurityIdentifier]) )
        {
            $groupSid = $group.Translate([Security.Principal.SecurityIdentifier])
            if ( $groupSid.IsWellKnown("AccountAdministratorSid") -or $groupSid.IsWellKnown("BuiltinAdministratorsSid"))
            {
                return $true
            }
        }
    }

    return $false
}

Set-Alias -Name 'Test-AdminPrivileges' -Value 'Test-AdminPrivilege'
