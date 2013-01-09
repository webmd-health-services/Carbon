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

function Get-IisAppPool
{
    <#
    .SYNOPSIS
    Gets a `Microsoft.Web.Administration.ApplicationPool` object for an application pool.
    
    .DESCRIPTION
    Use the `Microsoft.Web.Administration` API to get a .NET object for an application pool.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.applicationpool(v=vs.90).aspx
    
    .OUTPUTS
    Microsoft.Web.Administration.ApplicationPool.
    
    .EXAMPLE
    Get-IisAppPool -Name 'Batcave'
    
    Gets the `Batcave` application pool.
    
    .EXAMPLE
    Get-IisAppPool -Name 'Missing!'
    
    Returns `null` since, for purposes of this example, there is no `Missing~` application pool.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the application pool to return.
        $Name
    )
    
    $mgr = New-Object Microsoft.Web.Administration.ServerManager
    $mgr.ApplicationPools |
        Where-Object { $_.Name -eq $Name } |
        Add-IisServerManagerMember -ServerManager $mgr -PassThru
}