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

function Get-BBServerBranch
{
    <#
    .SYNOPSIS
    Gets a list of branches from a repository.

    .DESCRIPTION
    The `Get-BBServerBranch` function returns a list of all branches in a Bitbucket Server repository.
    
    If you pass a branch name, the function will only return the information for the named branch and will return nothing if no branches are found that match the search criteria. Wildcards are allowed to search for files.

    .EXAMPLE
    Get-BBServerBranch -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo'

    Demonstrates how to get the properties of all branches in the `TestRepo` repository.

    .EXAMPLE
    Get-BBServerBranch -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -BranchName 'master'

    Demonstrates how to get the properties for the master branch in the `TestRepo` repository.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that defines what Bitbucket Server to connect to and the credentials to use when connecting.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository resides. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of a specific repository.
        $RepoName,

        [string]
        # The name of the branch to search for.
        $BranchName
    )
    
    Set-StrictMode -Version 'Latest'
    
    $resourcePath = ('projects/{0}/repos/{1}/branches' -f $ProjectKey, $RepoName)
    $nextPageStart = 0
    $isLastPage = $false
    $branchList = $null
    
    while( $isLastPage -eq $false )
    {
        $getBranches = Invoke-BBServerRestMethod -Connection $Connection -Method 'GET' -ApiName 'api' -ResourcePath ('{0}?limit={1}&start={2}' -f $resourcePath, [int16]::MaxValue, $nextPageStart)
        if( $getBranches.isLastPage -eq $false )
        {
            $nextPageStart = $getBranches.nextPageStart
        }
        else
        {
            $isLastPage = $true
        }

        $branchList += $getBranches.values
    }
    
    if( $BranchName )
    {
        $branchList = $branchList | Where-Object { $_.displayId -like $BranchName }
    }
    
    return $branchList
}
