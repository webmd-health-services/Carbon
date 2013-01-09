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

function Assert-AdminPrivilege
{
    <#
    .SYNOPSIS
    Writes an error and returns false if the user doesn't have administrator privileges.

    .DESCRIPTION
    Many scripts and functions require the user to be running as an administrator.  This function checks if the user is running as an administrator or with administrator privileges and writes an error if the user doesn't.  

    .LINK
    Test-AdminPrivilege

    .EXAMPLE
    Assert-AdminPrivilege

    Writes an error that the user doesn't have administrator privileges.
    #>
    [CmdletBinding()]
    param(
    )
    
    if( -not (Test-AdminPrivilege) )
    {
        Write-Error "You are not currently running with administrative privileges.  Please re-start PowerShell as an administrator (right-click the PowerShell application, and choose ""Run as Administrator"")."
        return $false
    }
    return $true
}

Set-Alias -Name 'Assert-AdminPrivileges' -Value 'Assert-AdminPrivilege'
