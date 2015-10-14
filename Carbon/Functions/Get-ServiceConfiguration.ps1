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

function Get-ServiceConfiguration
{
    <#
    .SYNOPSIS
    Gets a service's full configuration, e.g. username, path, failure actions, etc.

    .DESCRIPTION
    The .NET `ServiceController` object only returns basic information about a service. This function returns a bunch of the missing configuration in the form of a `Carbon.Service.ServiceInfo` object:
    
     * Account name/user name
     * Path
     * Description
     * Failure actions

    You can load a specific service using its name, or pipe in `ServiceController` objects.

    In addition to this function, Carbon also adds this information as extended type data properties onto the `ServiceController` class. To see it, 

        Get-Service | Get-Member

    The user running this function must have `QueryConfig`, `QueryStatus`, and `EnumerateDependents` permissions on the service. Use `Grant-ServicePermission` to grant these permissions.

    This function is new in Carbon 1.8.

    .LINK
    Grant-ServicePermission

    .EXAMPLE
    Get-Service | Get-ServiceConfiguration

    Demonstrates how you can pipe in a `ServiceController` object to load the service. This works for services on remote computers as well.
    
    .EXAMPLE
    Get-ServiceConfiguration -Name  'w3svc'

    Demonstrates how you can get a specific service's configuration.

    .EXAMPLE
    Get-ServiceConfiguration -Name 'w3svc' -ComputerName 'enterprise'

    Demonstrates how to get service configuration for a service on a remote computer.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Service.ServiceInfo])]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true,Position=0)]
        [string]
        # The name of the service.
        $Name,

        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [Alias('MachineName')]
        [string]
        # The name of the computer where the service lives.
        $ComputerName
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        New-Object 'Carbon.Service.ServiceInfo' $Name,$ComputerName
    }
}
