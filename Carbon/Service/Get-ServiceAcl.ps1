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

function Get-ServiceAcl
{
    <#
    .SYNOPSIS
    Gets the discretionary access control list (i.e. DACL) for a service.
    
    .DESCRIPTION
    You wanted it, you got it!  You probably want to use `Get-ServicePermission` instead.  If you want to chagne a service's permissions, use `Grant-ServicePermission` or `Revoke-ServicePermissions`.
    
    .LINK
    Get-ServicePermission
    
    .LINK
    Grant-ServicePermission
    
    .LINK
    Revoke-ServicePermission
    
    .EXAMPLE
    Get-ServiceAcl -Name Hyperdrive
    
    Gets the `Hyperdrive` service's DACL.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service whose DACL to return.
        $Name
    )

    $rawSD = Get-ServiceSecurityDescriptor -Name $Name
    $rawDacl = $rawSD.DiscretionaryAcl
    New-Object Security.AccessControl.DiscretionaryAcl $false,$false,$rawDacl
}
