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

Set-StrictMode -Version 'Latest'

function Uninstall-Group
{
    <#
    .SYNOPSIS
    Removes a local group
    
    .DESCRIPTION
    Uses DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity() to search for a local group by name
    
    .PARAMETER Name    
    
    .EXAMPLE
    Uninstall-WhsGroup -Name 'TestGroup1'
    
    Removes group TestGroup1 from the local computer

    .INPUTS
    System.String

    .LINK
    Install-WhsGroup
    #>
    
    [CmdletBinding(SupportsShouldProcess=$true)]

    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        # Name of group to remove
        $Name
    )

	Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    $group = [DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity( $ctx, $Name )

    if ($PSCmdlet.ShouldProcess($Name, 'Delete local group'))
    {
        if ($group)
        {
            Write-Verbose ('Deleting local group {0}' -f $Name)
            $group.Delete()
        }
        else
        {
            Write-Verbose ('Local group {0} not found' -f $Name)
        }
    }

}