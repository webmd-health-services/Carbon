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

    If you want to get full identit information (domain, type, sid, etc.), use `Resolve-Identity`.

    .LINK
    Test-Identity

    .LINK
    Resolve-Identity

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx
    
    .OUTPUTS
    string
    
    .EXAMPLE
    Resolve-IdentityName -Name 'Administrators'
    
    Returns `BUILTIN\Administrators`, the canonical name for the local Administrators group.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the identity to return.
        $Name
    )

    Set-StrictMode -Version 'Latest'
    
    return Resolve-Identity -Name $Name -ErrorAction Ignore | Select-Object -ExpandProperty 'FullName'
}
