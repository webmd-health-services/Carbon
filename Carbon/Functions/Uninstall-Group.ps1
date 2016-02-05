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

function Uninstall-Group
{
    <#
    .SYNOPSIS
    Removes a *local* group.
    
    .DESCRIPTION
    The `Uninstall-Group` function removes a *local* group using .NET's [DirectoryServices.AccountManagement API](https://msdn.microsoft.com/en-us/library/system.directoryservices.accountmanagement.aspx). If the group doesn't exist, returns without doing any work or writing any errors.
    
    This function was added in Carbon 2.1.0.

    .LINK
    Add-GroupMember

    .LINK
    Install-Group

    .LINK
    Remove-GroupMember

    .LINK
    Test-Group

    .LINK
    Test-GroupMember

    .INPUTS
    System.String

    .EXAMPLE
    Uninstall-WhsGroup -Name 'TestGroup1'
    
    Demonstrates how to uninstall a group. In this case, the `TestGroup1` group is removed.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [String]
        # The name of the group to remove/uninstall.
        $Name
    )

	Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Group -Name $Name) )
    {
        return
    }

    $group = Get-Group -Name $Name
    if( -not $group )
    {
        return
    }

    if( $PSCmdlet.ShouldProcess(('local group {0}' -f $Name), 'remove') )
    {
        Write-Verbose -Message ('[{0}]              -' -f $Name)
        $group.Delete()
    }

}