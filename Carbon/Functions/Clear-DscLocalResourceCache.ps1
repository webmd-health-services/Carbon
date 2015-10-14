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

function Clear-DscLocalResourceCache
{
    <#
    .SYNOPSIS
    Clears the local DSC resource cache.

    .DESCRIPTION
    DSC caches resources. This is painful when developing, since you're constantly updating your resources. This function allows you to clear the DSC resource cache on the local computer. What this function really does, is kill the DSC host process running DSC.

    `Clear-DscLocalResourceCache` is new in Carbon 2.0.

    .EXAMPLE
    Clear-DscLocalResourceCache
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Get-WmiObject msft_providers | 
        Where-Object {$_.provider -like 'dsccore'} | 
        Select-Object -ExpandProperty HostProcessIdentifier | 
        ForEach-Object { Get-Process -ID $_ } | 
        Stop-Process -Force
}
