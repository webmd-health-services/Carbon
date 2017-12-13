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

function Move-BBServerRepository
{
    <#
    .SYNOPSIS
    Move a repository in Bitbucket Server from one project to another.

    .DESCRIPTION
    The `Move-BBServerRepository` moves a repository in Bitbucket Server.

    Use the `New-BBServerConnection` function to create a connection object to pass to the `Connection` parameter.

    .EXAMPLE
    Move-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -RepoName 'fubarsnafu' -TargetProjectKey 'BBSA_NEW'

    Demonstrates how to move the repository 'fubarsnafu' from the 'BBSA' project to the 'BBSA_NEW'
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
        # The name of a specific repository to move to the new project.
        $RepoName,

        [Parameter(Mandatory=$true)]
        # The key/ID that identifies the target project where the repository will be moved. This is *not* the project name.
        $TargetProjectKey
    )
    
    Set-StrictMode -Version 'Latest'

    $resourcePath = ('projects/{0}/repos/{1}' -f $ProjectKey, $RepoName)
    
    $getProjects = Get-BBServerProject -Connection $Connection

    $currentProject = $getProjects | Where-Object { $_.key -eq $ProjectKey }
    if( !$currentProject )
    {
        Write-Error -Message ('A project with key/ID ''{0}'' does not exist. Specified repository cannot be moved.' -f $ProjectKey)
        return
    }
    
    $targetProject = $getProjects | Where-Object { $_.key -eq $TargetProjectKey }
    if( !$targetProject )
    {
        Write-Error -Message ('A project with key/ID ''{0}'' does not exist. Specified repository cannot be moved.' -f $TargetProjectKey)
        return
    }
    
    $currentRepo = Get-BBServerRepository -Connection $Connection -ProjectKey $ProjectKey | Where-Object { $_.name -eq $RepoName }
    if( !$currentRepo )
    {
        Write-Error -Message ('A repository with name ''{0}'' does not exist in the project ''{1}''. Specified respository cannot be moved.' -f $RepoName, $ProjectKey)
        return
    }
        
    $repoProjectConfig = @{ project = @{ key = $TargetProjectKey } }
    $setRepoProject = Invoke-BBServerRestMethod -Connection $Connection -Method 'PUT' -ApiName 'api' -ResourcePath $resourcePath -InputObject $repoProjectConfig
    
    return $setRepoProject
}
