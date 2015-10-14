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

function Uninstall-IisWebsite
{
    <#
    .SYNOPSIS
    Removes a website

    .DESCRIPTION
    Pretty simple: removes the website named `Name`.  If no website with that name exists, nothing happens.

    Beginning with Carbon 2.0.1, this function is not available if IIS isn't installed.

    .LINK
    Get-IisWebsite
    
    .LINK
    Install-IisWebsite
    
    .EXAMPLE
    Uninstall-IisWebsite -Name 'MyWebsite'
    
    Removes MyWebsite.

    .EXAMPLE
    Uninstall-IisWebsite 1

    Removes the website whose ID is 1.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0,Mandatory=$true)]
        [string]
        # The name or ID of the website to remove.
        $Name
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( Test-IisWebsite -Name $Name )
    {
        $manager = New-Object 'Microsoft.Web.Administration.ServerManager'
        try
        {
            $site = $manager.Sites | Where-Object { $_.Name -eq $Name }
            $manager.Sites.Remove( $site )
            $manager.CommitChanges()
        }
        finally
        {
            $manager.Dispose()
        }
    }
}

Set-Alias -Name 'Remove-IisWebsite' -Value 'Uninstall-IisWebsite'

