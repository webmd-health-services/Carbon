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

function Add-PSTypeName
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='RepositoryInfo')]
        [Switch]
        $RepositoryInfo,

        [Parameter(Mandatory=$true,ParameterSetName='ProjectInfo')]
        [Switch]
        $ProjectInfo,

        [Parameter(Mandatory=$true,ParameterSetName='CommmitBuildStatusInfo')]
        [Switch]
        $CommitBuildStatusInfo
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $typeName = 'Atlassian.Bitbucket.Server.{0}' -f $PSCmdlet.ParameterSetName
        $InputObject.pstypenames.Add( $typeName )

        if( $ProjectInfo )
        {
            if( -not ($InputObject | Get-Member -Name 'description') )
            {
                $InputObject | Add-Member -MemberType NoteProperty -Name 'description' -Value ''
            }
        }

        $InputObject
    }
}