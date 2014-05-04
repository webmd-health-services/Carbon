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

function Assert-FirewallConfigurable
{
    <#
    .SYNOPSIS
    Asserts that the Windows firewall is configurable and writes an error if it isn't.

    .DESCRIPTION
    The Windows firewall can only be configured if it is running.  This function checks test if it is running.  If it isn't, it writes out an error and returns `False`.  If it is running, it returns `True`.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Assert-FirewallConfigurable

    Returns `True` if the Windows firewall can be configured, `False` if it can't.
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    if( (Get-Service 'Windows Firewall').Status -ne 'Running' ) 
    {
        Write-Error "Unable to configure firewall: Windows Firewall service isn't running."
        return $false
    }
    return $true
}
