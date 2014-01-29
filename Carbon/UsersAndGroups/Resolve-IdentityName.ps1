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


function Resolve-IdentityName
{
    <#
    .SYNOPSIS
    Determines the full, NT identity name for a user or group.
    
    .DESCRIPTION
    The common name for an account is not always the canonical name used by the operating system.  For example, the local Administrators group is actually called BUILTIN\Administrators.  This function converts an identity's name into its canonical name.
    
    If the name doesn't represent an actual user or group, an error is written and nothing returned.
    
    .OUTPUTS
    System.String.
    
    .EXAMPLE
    Resolve-IdentityName -Identity 'Administrators'
    
    Returns `BUILTIN\Administrators`, the canonical name for the local Administrators group.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the identity whose canonical name to return.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    
    if( Test-Identity -Name $Name )
    {
        return [Carbon.Identity]::FindByName( $Name ) | Select-Object -ExpandProperty 'FullName'
    }

    return $null
}
