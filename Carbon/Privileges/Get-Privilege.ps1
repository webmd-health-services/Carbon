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

function Get-Privilege
{
    <#
    .SYNOPSIS
    Gets an identity's privileges.
    
    .DESCRIPTION
    These privileges are usually managed by Group Policy and control the system operations and types of logons a user/group can perform.
    
    Note: if a computer is not on a domain, this function won't work.
    
    .OUTPUTS
    System.String
    
    .LINK
    Grant-Privilege
    
    .LINK
    Revoke-Prvileges
    
    .LINK
    Test-Privilege
    
    .EXAMPLE
    Get-Privilege -Identity TheBeast
    
    Gets `TheBeast`'s privileges as an array of strings.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity whose privileges to return.
        $Identity
    )
    
    [Carbon.Lsa]::GetPrivileges( $Identity )
}

Set-Alias -Name 'Get-Privileges' -Value 'Get-Privilege'
