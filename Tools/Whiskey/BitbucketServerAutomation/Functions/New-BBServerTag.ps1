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

function New-BBServerTag
{
    <#
    .SYNOPSIS
    Creates a new Version Tag on a commit in Bitbucket Server.

    .DESCRIPTION
    The `New-BBServerTag` function creates a new Git Tag with Version information on a commit in Bitbucket Server. It requires a commit to exist in a repository, and a project to exist where the repository should live (all repositories in Bitbucket Server are part of a project).

    By default, the tag will be lightweight and will not contain a tag message. However, those properties can both be overridden with their respective parameters. To add a message to the Tag, utilize the $Message parameter, and if you would prefer to use an annotated tag, use the parameter $Type = 'ANNOTATED'

    Use the `New-BBServerConnection` function to generate the connection object, `New-BBServerRepository` to generate the repository object, and `New-BBServerProject` to generate the project, which should be passed in as the `$Connection`, `$RepositoryKey`, and `$ProjectKey` parameters.

    The `$Force` parameter will allow the user to force the tag to be generated for that commit regardless of the tags use on other commits in the repo.

    .EXAMPLE
    New-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName -name $TagName -CommitID $commitHash

    Demonstrates the default behavior of tagging a commit with a version tag.

    .EXAMPLE
    New-BBServerTag -Connection $conn -ProjectKey $key -RepositoryKey $repoName -name $TagName -CommitID $commitHash -Message 'Tag Message' -Force -Type 'ANNOTATED'

    Demonstrates how to tag a commit with an annotated tag containing a tag message with the force parameter enabled.
    #>

    [CmdletBinding()]
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
        $RepositoryKey,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The tag's name/value.
        $Name,
 
        [Parameter(Mandatory=$true)]
        [string]
        # The commit ID the tag should point to. In the Bitbucket Server API documentation, this is called the `startPoint`.
        $CommitID,
 
        [string]
        # An optional message for the commit that creates the tag.
        $Message = "",

        [Switch]
        $Force,

        [String]
        $Type = "LIGHTWEIGHT"
 
    )
 
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $tag = @{
                name = $Name
                startPoint = $CommitID
                message = $Message
                type = $Type
                }
    if( $Force )
    {
        $tag['force'] = "true"
    }

    $result = $tag | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'git' -ResourcePath ('projects/{0}/repos/{1}/tags' -f $ProjectKey, $RepositoryKey)
    if (-not $result)
    {
        Write-Error ("Unable to tag commit {0} with {1}." -f $CommitID, $Name)
    }
}
 