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

function Get-IisApplication
{
    <#
    .SYNOPSIS
    Gets an IIS application as an `Application` object.

    .DESCRIPTION
    Uses the `Microsoft.Web.Administration` API to get an IIS application object.  If the application doesn't exist, `$null` is returned.

    The objects returned have two dynamic properties and one dynamic methods added.

     * `ServerManager { get; }` - The `ServerManager` object which created the `Application` object.
     * `CommitChanges()` - Persists any configuration changes made to the object back into IIS's configuration files.
     * `PhysicalPath { get; }` - The physical path to the application.

    .OUTPUTS
    Microsoft.Web.Administration.Application.

    .EXAMPLE
    Get-IisApplication -SiteName 'DeathStar`

    Gets the application running the `DeathStar` website.

    .EXAMPLE
    Get-IisApplication -SiteName 'DeathStar' -Name 'MainPort/ExhaustPort'

    Demonstrates how to get a nested application, i.e. gets the application at `/MainPort/ExhaustPort` under the `DeathStar` website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the application should be created.
        $SiteName,
        
        [Parameter()]
        [string]
        # The name of the application.  Default is `/`, or the application running the website given by the `SiteName` parameter.
        $Name = '/'
    )

    $site = Get-IisWebsite -SiteName $SiteName
    if( -not $site )
    {
        return
    }
    $site.Applications |
        Where-Object { $_.Path -eq "/$Name" } | 
        Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru |
        Add-Member -MemberType ScriptProperty -Name PhysicalPath -Value {
            $this.VirtualDirectories |
                Where-Object { $_.Path -eq '/' } |
                Select-Object -ExpandProperty PhysicalPath
        } -PassThru
}