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

function Test-Identity
{
    <#
    .SYNOPSIS
    Tests that a name is a valid Windows local or domain user/group.
    
    .DESCRIPTION
    Attempts to convert an identity name into a `System.Security.Principal.SecurityIdentifer` object.  If the conversion succeeds, the name belongs to a valid local or domain user/group.  If conversion fails, the user/group doesn't exist. You can also optionally return the applicable `SecurityIdentifier` object.
    
    If the identity testing is in another domain, and there is no trust relationship between the current domain the identity's domain, `$false` will be returned even though the account could exist.
    
    .EXAMPLE
    Test-Identity -Name 'Administrators
    
    Tests that a user or group called `Administrators` exists on the local computer.
    
    .EXAMPLE
    Test-Identity -Name 'CARBON\Testers'
    
    Tests that a group called `Testers` exists in the `CARBON` domain.
    
    .EXAMPLE
    Test-Identity -Name 'Tester' -PassThru
    
    Tests that a user or group named `Tester` exists and returns a `System.Security.Principal.SecurityIdentifier` object if it does.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the identity to test.
        $Name,
        
        [Switch]
        # Returns a `System.Security.Principal.SecurityIdentifier` object if the identity exists.
        $PassThru
    )

    Set-StrictMode -Version 'Latest'

    $identity = [Carbon.Identity]::FindByName( $Name )
    if( -not $identity )
    {
        return $false
    }

    if( $PassThru )
    {
        return $identity.Sid
    }
    return $true
}
