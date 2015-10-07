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
    
    $ctxType = 'Domain'
    $ctxName = $Identity.Domain
    if( $Identity.Domain -eq $env:COMPUTERNAME -or $Identity.Domain -eq 'BUILTIN' -or $Identity.Domain -eq 'NT AUTHORITY' )
    {
        $ctxName = $env:COMPUTERNAME
        $ctxType = 'Machine'
    }
    New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctxType,$ctxName
}