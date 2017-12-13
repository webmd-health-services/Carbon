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

function Get-BBServerTag 
{
    <#
    .SYNOPSIS
    Gets tags from a repository in Bitbucket Server.

    .DESCRIPTION
    The `Get-BBServerTag` function returns the git tags associated with a particular repository in Bitbucket Server. It will one or more of the most recent git tags in a repo, up to a max of 25, after which it will truncate the least recent tags in favor of the most recent tags. If the repo has zero tags an error will be thrown.

    The tags are obtained through a rest call, and the return from that call is a collection of JSON objects with the related Tag information. This is returned from `Get-BBServerTag` in the form of a list of PowerShell Objects.

    .EXAMPLE
    Get-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName

    Demonstrates how to obtain the git tags associated with a particular repository
    #>
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,    
  
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository's project.
        $ProjectKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The key of the repository.
        $RepositoryKey

    )
  
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    $limit = [int16]::MaxValue
    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}/tags?limit={2}' -f $ProjectKey, $RepositoryKey, $limit) |
        Select-Object -ExpandProperty 'values'
}

 
