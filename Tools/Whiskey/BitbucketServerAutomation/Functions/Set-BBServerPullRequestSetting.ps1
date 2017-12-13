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

function Set-BBServerPullRequestSetting
{
    <#
    .SYNOPSIS
    Sets the pull request settings for a repository.

    .DESCRIPTION
    The `Set-BBServerPullRequestSetting` function sets the specified pull request settings for a Bitbucket Server repository.
    
    .EXAMPLE
    Set-BBServerPullRequestSetting -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -RequiredApprovers 2 -RequiredAllApprovers

    Demonstrates how to set the pull request settings in the `TestRepo` repository as follows:
        Minimum of 2 approvers must approve; All selected approvers must approve

    .EXAMPLE
    Set-BBServerPullRequestSetting -Connection $conn -ProjectKey 'TestProject' -RepoName 'TestRepo' -RequiredApprovers 1 -UnapproveOnUpdate $false

    Demonstrates how to set the pull request settings in the `TestRepo` repository as follows:
        Minimum of 1 approver must approve; Prior approvals will *not* be removed if the pull request is updated.
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
        
        [int]
        # The minimum number of users that must approve a pull request before it can be merged.
        $RequiredApprovers,
        
        [boolean]
        # Whether or not all approvers must approve a pull request before it can be merged.
        $RequiredAllApprovers,

        [boolean]
        # Whether or not reviewers approvals will be removed if new commits are pushed or the pull request is retargeted to a different branch.
        $UnapproveOnUpdate
    )
    
    Set-StrictMode -Version 'Latest'
    
    $resourcePath = ('projects/{0}/repos/{1}/settings/pull-requests' -f $ProjectKey, $RepoName)
    $pullRequestSettingConfig = @{}
    
    if( $RequiredApprovers )
    {
        $pullRequestSettingConfig += @{ requiredApprovers = $RequiredApprovers }
    }
    
    if( $MyInvocation.BoundParameters.ContainsKey('RequiredAllApprovers') )
    {
        if( $RequiredAllApprovers )
        {
            $pullRequestSettingConfig += @{ requiredAllApprovers = $true }
        }
        else
        {
            $pullRequestSettingConfig += @{ requiredAllApprovers = $false }
        }
    }

    if( $MyInvocation.BoundParameters.ContainsKey('UnapproveOnUpdate') )
    {
        if( $UnapproveOnUpdate )
        {
            $pullRequestSettingConfig += @{ unapproveOnUpdate = $true }
        }
        else
        {
            $pullRequestSettingConfig += @{ unapproveOnUpdate = $false }
        }
    }
    
    $pullRequestSettings = Invoke-BBServerRestMethod -Connection $Connection -Method 'POST' -ApiName 'api' -ResourcePath $resourcePath -InputObject $pullRequestSettingConfig
    
    return $pullRequestSettings
}
