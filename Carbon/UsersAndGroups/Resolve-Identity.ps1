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


function Resolve-Identity
{
    <#
    .SYNOPSIS
    Determines the identity of a user or group using its name.
    
    .DESCRIPTION
    The common name for an account is not always the canonical name used by the operating system.  For example, the local Administrators group is actually called BUILTIN\Administrators.  This function resolves an identity's name into its domain, name, full name, SID, and SID type. It returns a `Carbon.Identity` object with the following properties:

     * Domain - the domain the user was found in
     * FullName - the users full name, e.g. Domain\Name
     * Name - the user's username or the group's name
     * Type - the Sid type.
     * Sid - the account's security identifier as a `System.Security.Principal.SecurityIdentifier` object.
    
    If the name doesn't represent an actual user or group, an error is written and nothing returned.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx
    
    .OUTPUTS
    Carbon.Identity.
    
    .EXAMPLE
    Resolve-IdentityName -Name 'Administrators'
    
    Returns an object representing the `Administrators` group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the identity to return.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    
    if( -not (Test-Identity -Name $Name) )
    {
        Write-Error ('Identity ''{0}'' not found.' -f $Name)
        return
    }

    return [Carbon.Identity]::FindByName( $Name ) | Select-Object -ExpandProperty 'FullName'
}

Set-Alias -Name 'Resolve-IdentityName' -Value 'Resolve-Identity'