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

function Get-BBServerCommitBuildStatus
{
    <#
    .SYNOPSIS
    Gets the build status of a commit.

    .DESCRIPTION
    The `Get-BBServerCommitBuildStatus` function gets the build status for a specific commit. The commit ID is the full sha1 identifer Git uses to uniquely identify a commit, e.g. `e00cf62997a027bbf785614a93e2e55bb331d268`. There may be more than one status if a commit was built multiple times.

    The returned object(s) will have the following properties:

    * `state`: Indicates whether the build passed, failed, or is in progress. Its value will be one of `SUCCESSFUL`, `INPROGRESS` or `FAILED`
    * `key`: A unique value that identifies the build. Usually only means something to the original build system.
    * `name`: The name of the build.
    * `url`: The URI to the build.
    * `description`: A description of the build.
    * `dateAdded`: The date/time the status was added to Bitbucker Server.

    .EXAMPLE
    Get-BBServerCommitBuildStatus -Connection $conn -CommitID 'e00cf62997a027bbf785614a93e2e55bb331d268'

    Demonstrates how to get the build status for a commit.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The connection to the Bitbucket Server. Use `New-BBServerConnection` to create one.
        $Connection,

        [Parameter(Mandatory=$true)]
        [ValidateLength(1,255)]
        [string]
        # The ID of the commit. This is the full sha1 identifer Git uses to uniquely identify a commit, e.g. `e00cf62997a027bbf785614a93e2e55bb331d268`.
        $CommitID
    )

    Set-StrictMode -Version 'Latest'

    $epochStart = Get-Date -Year 1970 -Month 1 -Day 1 -Hour 0 -Minute 0 -Second 0 -Millisecond 0

    Invoke-BBServerRestMethod -Connection $Connection -Method Get -ApiName 'build-status' -ResourcePath ('commits/{0}' -f $CommitID) |
        Select-Object -ExpandProperty 'values' |
        Add-PSTypeName -CommitBuildStatusInfo |
        ForEach-Object { $_.dateAdded = $epochStart.AddSeconds(([double]$_.dateAdded) / 1000) ; $_ }
    
}
