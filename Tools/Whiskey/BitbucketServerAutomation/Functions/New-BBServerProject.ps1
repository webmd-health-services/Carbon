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

function New-BBServerProject
{
    <#
    .SYNOPSIS
    Creates a new project.

    .DESCRIPTION
    The `New-BBServerProject` function creates a new Bitbucket Server projects. All repositories in Bitbucket Server must be part of a project. Projects are used to group like repositories together. 

    Typically, source control repositories should be organized around your code and software, not your teams and organizations. Teams and organizations change more frequently than the technology and purpose of software, so organizing by your code leads to a more stable structure.

    .LINK
    https://confluence.atlassian.com/bitbucket/projects-792497956.html

    .EXAMPLE
    New-BBServerProject -Connection $conn -Key 'FBR' -Name 'Fubar Snafu'

    Demonstrates how to create a Bitbucket Server project. In this case a new project with key `FBR` and name `Fubar Snafu` will be created in the Bitbucket Server instance represented in the `$conn` object.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting. Use `New-BBServerConnection` to create connection objects.
        $Connection,

        [Parameter(Mandatory=$true)]
        [ValidatePattern('^[A-Za-z][A-Za-z0-9_]+$')]
        [ValidateLength(1,128)]
        [string]
        # A unique identifier for the project. Keys must begin with a letter and contain only letters, numbers, or underscore (e.g. `_`). It must be less than 128 characters.
        $Key,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the project. 
        $Name,

        [string]
        # A description of the project.
        $Description
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $request = @{
                    key = $Key;
                    name = $Name;
                    description = $Description;
                } 
    $project = $request | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'api' -ResourcePath 'projects' | Add-PSTypeName -ProjectInfo
    if( -not $project )
    {
        return
    }

    return $project
}