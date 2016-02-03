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

function Get-IdentityPrincipalContext
{
    <#
    .SYNOPSIS
    **INTERNAL.** Do not use.
    .DESCRIPTION
    **INTERNAL.** Do not use.
    .EXAMPLE
    **INTERNAL.** Do not use.
    #>
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.PrincipalContext])]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Identity]
        # The identity whose principal context to get.
        $Identity
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # First, check for a local match
    $machineCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' 'Machine',$env:COMPUTERNAME
    if( [DirectoryServices.AccountManagement.Principal]::FindByIdentity( $machineCtx, 'Sid', $Identity.Sid.Value ) )
    {
        return $machineCtx
    }

    $domainCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' 'Domain',$Identity.Domain
    if( [DirectoryServices.AccountManagement.PRincipal]::FindByIdentity( $domainCtx, 'Sid', $Identity.Sid.Value ) )
    {
        return $domainCtx
    }

    Write-Error -Message ('Unable to determine if principal ''{0}'' (SID: {1}; Type: {2}) is a machien or domain principal.' -f $Identity.FullName,$Identity.Sid.Value,$Identity.Type)
}
