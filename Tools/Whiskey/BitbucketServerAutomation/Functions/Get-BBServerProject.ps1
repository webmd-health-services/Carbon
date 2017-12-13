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

function Get-BBServerProject
{
    <#
    .SYNOPSIS
    Gets projects.

    .DESCRIPTION
    The `Get-BBServerProject` function gets all projects in a Bitbucket Server instance. If you pass it a name, it will get just that project. Wildcards are allowed to search for projects. Wildcard matching is *not* supported by the Bitbucket Server API, so all projects must be retrieved and searched.

    .LINK
    https://confluence.atlassian.com/bitbucket/projects-792497956.html

    .EXAMPLE

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [string]
        # The name of the project to get. Wildcards allowed. The wildcard search is done on the *client* (i.e. this computer) not the server. All projects are fetched from Bitbucket Server first. This may impact performance.
        $Name
    )
    
    Set-StrictMode -Version 'Latest'

    $resourcePath = 'projects'
    if( $Name )
    {
        $resourcePath = '{0}?name={1}' -f $resourcePath,$Name
    }
    else
    {
        $resourcePath = '{0}?limit={1}' -f $resourcePath,[int16]::MaxValue
    }

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath $resourcePath  |
        Select-Object -ExpandProperty 'values' |
        Add-PSTypeName -ProjectInfo
}