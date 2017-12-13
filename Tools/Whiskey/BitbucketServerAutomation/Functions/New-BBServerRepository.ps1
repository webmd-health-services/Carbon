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

function New-BBServerRepository
{
    <#
    .SYNOPSIS
    Creates a new repository in Bitbucket Server.

    .DESCRIPTION
    The `New-BBServerRepository` function creates a new Git repository in Bitbucket Server. It requires an project to exist where the repository should exist (all repositories in Bitbucket Server are part of a project).

    By default, the repository is setup to allow forking and be private. To disable forking, use the `NotForkable` switch. To make the repository public, use the `Public` switch.

    Use the `New-BBServerConnection` function to generate the connection object that should get passed to the `Connection` parameter.

    .EXAMPLE
    New-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -Name 'fubarsnafu'

    Demonstrates how to create a repository.

    .EXAMPLE
    New-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -Name 'fubarsnafu' -NotForkable -Public

    Demonstrates how to create a repository with different default settings. The repository will be not be forkable and will be public, not private.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The connection information that describe what Bitbucket Server instance to connect to, what credentials to use, etc. Use the `New-BBServerConnection` function to create a connection object.
        $Connection,

        [Parameter(Mandatory=$true)]
        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true)]
        [ValidateLength(1,128)]
        [string]
        # The name of the repository to create.
        $Name,

        [Switch]
        # Disable the ability to fork the repository. The default is to allow forking.
        $NotForkable,

        [Switch]
        # Make the repository public. Not sure what that means.
        $Public
    )

    Set-StrictMode -Version 'Latest'

    $forkable = $true
    if( $NotForkable )
    {
        $forkable = $false
    }

    $newRepoInfo = @{
                        name = $Name;
                        scmId = 'git';
                        forkable = $forkable;
                        public = [bool]$Public;
                    }

    $repo = $newRepoInfo | Invoke-BBServerRestMethod -Connection $Connection -Method Post -ApiName 'api' -ResourcePath ('projects/{0}/repos' -f $ProjectKey)
    if( $repo )
    {
        $repo | Add-PSTypeName -RepositoryInfo
    }
}