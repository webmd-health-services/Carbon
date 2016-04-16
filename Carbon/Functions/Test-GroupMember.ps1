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

function Test-GroupMember
{
    <#
    .SYNOPSIS
    Tests if a user or group is a member of a *local* group.

    .DESCRIPTION
    The `Test-GroupMember` function tests if a user or group is a member of a *local* group using [.NET's DirectoryServices.AccountManagement APIs](https://msdn.microsoft.com/en-us/library/system.directoryservices.accountmanagement.aspx). If the group or member you want to check don't exist, you'll get errors and `$null` will be returned. If `Member` is in the group, `$true` is returned. If `Member` is not in the group, `$false` is returned.

    The user running this function must have permission to access whatever directory the `Member` is in and whatever directory current members of the group are in.

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
    Uninstall-Group

    .EXAMPLE
    Test-GroupMember -GroupName 'SithLords' -Member 'REBELS\LSkywalker'

    Demonstrates how to test if a user is a member of a group. In this case, it tests if `REBELS\LSkywalker` is in the local `SithLords`, *which obviously he isn't*, so `$false` is returned.
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group whose membership is being tested.
        $GroupName,

        [Parameter(Mandatory=$true)]
        [string] 
        # The name of the member to check.
        $Member
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Group -Name $GroupName) )
    {
        Write-Error -Message ('Group ''{0}'' not found.' -f $GroupName)
        return
    }

    $group = Get-Group -Name $GroupName
    if( -not $group )
    {
        return
    }
    
    $principal = Resolve-Identity -Name $Member
    if( -not $principal )
    {
        return
    }

    try
    {
        return $principal.IsMemberOfLocalGroup($group.Name)
    }
    catch
    {
        Write-Error -Message ('Checking if ''{0}'' is a member of local group ''{1}'' failed: {2}' -f $principal.FullName,$group.Name,$_)
    }
}