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

function Remove-BBServerRepository
{
    <#
    .SYNOPSIS
    Remove a repository from Bitbucket Server.

    .DESCRIPTION
    The `Remove-BBServerRepository` deletes a repository from Bitbucket Server. This is a dangerous operation as all related data is also deleted. You will have to confirm the deletion. To force the deletion without being confirmed, use the `Force` switch.

    Use the `New-BBServerConnection` function to create a connection object to pass to the `Connection` parameter.

    .EXAMPLE
    Remove-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -Name 'fubarsnafu'

    Demonstrates how to delete a repository. Because deleting a repository is a high-impact operation, you will asked to confirm the deletion.

    .EXAMPLE
    Remove-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -Name 'fubarsnafu' -Force

    Demonstrates how to delete a repository, skipping any confirmation dialogs. This can be dangerous since deletions can't be undone. Use the `Force` switch with care.

    .EXAMPLE
    Get-BBServerRepository -Connection $conn -ProjectKey 'BBSA' -Name 'snafu' | Remove-BBServerRepository -Connection $conn

    Demonstrates that you can pipe objects returned by `Get-BBServerRepository` to `Remove-BBServerRepository`. When you pipe repository objects, you don't have to provide the project key

    .EXAMPLE
    'fubarsnafu' | Remove-BBServerRepository -Connection $conn -ProjectKey 'BBSA'

    Demonstrates that you can pipe repository names to `Remove-BBServerRepository`. When you do, you *must* also provide the project key.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact="High")]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The connection information that describe what Bitbucket Server instance to connect to, what credentials to use, etc. Use the `New-BBServerConnection` function to create a connection object.
        $Connection,

        [string]
        # The key/ID that identifies the project where the repository will be created. This is *not* the project name.
        $ProjectKey,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object]
        # The name of a specific repository to get.
        $Name,

        [Switch]
        # Don't prompt the user to confirm the deletion of the repository. This is a dangerous switch to use, since repository deletions can't be undone. 
        $Force
    )

    process 
    {
        Set-StrictMode -Version 'Latest'
    
        if( $Name.pstypenames -contains 'Atlassian.Bitbucket.Server.RepositoryInfo' )
        {
            $repoInfo = $Name
            $Name = $repoInfo.name
            if( -not $Name )
            {
                Write-Error -Message ('Repository name not found. Looks like you piped in an invalid repository object because either we can''t find the `name` property or it doesn''t have a value.')
                return
            }

            $ProjectKey = $repoInfo.project.key
            if( -not $ProjectKey )
            {
                Write-Error -Message ('Project key not found. Looks like you piped in an invalid repository object becuse either the `project.key` properties don''t exist or they don''t have values.')
                return
            }
        }

        if( -not $ProjectKey )
        {
            Write-Error -Message ('ProjectKey parameter missing. When passing the name of a repository with the Name parameter you must also pass the repository''s project key with the ProjectKey parameter.')
            return
        }

        $whatIfMessage = 'removing repository ''{0}/{1}'' from {2}' -f $ProjectKey,$Name,$Connection.Uri
        $confirmMessage = 'Do you want to remove repository ''{0}/{1}'' from {2}?{3}{3}This operation is PERMANENT and can''t be undone!' -f $ProjectKey,$Name,$Connection.Uri,[Environment]::NewLine
        if( $Force -or $PSCmdlet.ShouldProcess($whatIfMessage,$confirmMessage,'Confirm Permanently Deleting Repository') )
        {
            $result = Invoke-BBServerRestMethod -Connection $Connection -Method Delete -ApiName 'api' -ResourcePath ('projects/{0}/repos/{1}' -f $projectKey,$Name) -Verbose
        
            if( $result )
            {
                $result | ConvertTo-Json | Write-Verbose
            }
        }
    }
}
