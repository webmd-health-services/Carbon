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
    The `Get-IisAppPool` function returns an IIS application pools as a `Microsoft.Web.Administration.ApplicationPool` object. Use the `Name` parameter to return the application pool. If that application pool isn't found, `$null` is returned.

    Carbon adds a `CommitChanges` method on each object returned that you can use to save configuration changes.

    Beginning in Carbon 2.0, `Get-IisAppPool` will return all application pools installed on the current computer.
    
    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .LINK
    http://msdn.microsoft.com/en-us/library/microsoft.web.administration.applicationpool(v=vs.90).aspx
    
    .OUTPUTS
    Microsoft.Web.Administration.ApplicationPool.

    .EXAMPLE
    Get-IisAppPool

    Demonstrates how to get *all* application pools.
    
    .EXAMPLE
    Get-IisAppPool -Name 'Batcave'
    
    Gets the `Batcave` application pool.
    
    .EXAMPLE
    Get-IisAppPool -Name 'Missing!'
    
    Returns `null` since, for purposes of this example, there is no `Missing~` application pool.
    #>
    [CmdletBinding()]
    [OutputType([Microsoft.Web.Administration.ApplicationPool])]
    param(
        [string]
        # The name of the application pool to return. If not supplied, all application pools are returned.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $mgr = New-Object Microsoft.Web.Administration.ServerManager
    $mgr.ApplicationPools |
        Where-Object { 
            if( -not $PSBoundParameters.ContainsKey('Name') )
            {
                return $true
            }
            return $_.Name -eq $Name 
        } |
        Add-IisServerManagerMember -ServerManager $mgr -PassThru
}

