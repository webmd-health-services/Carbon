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

function Rename-BBServerRepository
{
    <#
    .SYNOPSIS
    Rename a repository in Bitbucket Server.

    .DESCRIPTION
    The `Rename-BBServerRepository` renames a repository in Bitbucket Server.

    Use the `New-BBServerConnection` function to create a connection object to pass to the `Connection` parameter.

    .EXAMPLE
    Rename-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -RepoName 'fubarsnafu' -TargetRepoName 'snafu_fubar'

    Demonstrates how to rename a repository from 'fubarsnafu' to 'snafu_fubar'.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The connection information that describe what Bitbucket Server instance to connect to, what credentials to use, etc. Use the `New-BBServerConnection` function to create a connection object.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository currently resides. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [object]
        # The name of a specific repository to rename.
        $RepoName,

        [Parameter(Mandatory=$true)]
        # The target name that the repository will be renamed to.
        $TargetRepoName
    )
    
    Set-StrictMode -Version 'Latest'

    $resourcePath = ('projects/{0}/repos/{1}' -f $ProjectKey, $RepoName)
    
    $getRepos = Get-BBServerRepository -Connection $Connection -ProjectKey $ProjectKey
    
    $currentRepo = $getRepos | Where-Object { $_.name -eq $RepoName }
    if( !$currentRepo )
    {
        Write-Error -Message ('A repository with name ''{0}'' does not exist in the project ''{1}''. Specified respository cannot be renamed.' -f $RepoName, $ProjectKey)
        return
    }
    
    $targetRepo = $getRepos | Where-Object { $_.name -eq $TargetRepoName }
    if( $targetRepo )
    {
        Write-Error -Message ('A repository with name ''{0}'' already exists in the project ''{1}''. Specified respository cannot be renamed.' -f $TargetRepoName, $ProjectKey)
        return
    }
        
    $repoRenameConfig = @{ name = $TargetRepoName }
    $setRepoName = Invoke-BBServerRestMethod -Connection $Connection -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath -InputObject $repoRenameConfig
    
    return $setRepoName
}
