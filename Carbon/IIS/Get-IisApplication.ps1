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

    Gets all the applications running under the `DeathStar` website.

    .EXAMPLE
    Get-IisApplication -SiteName 'DeathStar' -VirtualPath '/'

    Demonstrates how to get the main application for a website: use `/` as the application name.

    .EXAMPLE
    Get-IisApplication -SiteName 'DeathStar' -VirtualPath 'MainPort/ExhaustPort'

    Demonstrates how to get a nested application, i.e. gets the application at `/MainPort/ExhaustPort` under the `DeathStar` website.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The site where the application is running.
        $SiteName,
        
        [Parameter()]
        [Alias('Name')]
        [string]
        # The name of the application.  Default is to return all applications running under the website `$SiteName`.
        $VirtualPath
    )

    $site = Get-IisWebsite -SiteName $SiteName
    if( -not $site )
    {
        return
    }

    $site.Applications |
        Where-Object {
            if( $VirtualPath )
            {
                return ($_.Path -eq "/$VirtualPath")
            }
            return $true
        } | 
        Add-IisServerManagerMember -ServerManager $site.ServerManager -PassThru |
        Add-Member -MemberType ScriptProperty -Name PhysicalPath -Value {
            $this.VirtualDirectories |
                Where-Object { $_.Path -eq '/' } |
                Select-Object -ExpandProperty PhysicalPath
        } -PassThru
}