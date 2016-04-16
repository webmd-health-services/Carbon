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

function Add-GroupMember
{
    <#
    .SYNOPSIS
    Adds a users or groups to a *local* group.

    .DESCRIPTION
    You would think it's pretty easy and straight-forward to add users/groups to a local group, but you would be wrong.  The quick solution is to use `net localgroup`, but that won't accept user/group names longer than 24 characters.  This means you have to use the .NET Directory Services APIs.  How do you reliably add both users *and* groups?  What if those users are in a domain?  What if they're in another domain?  What about built-in users?  Fortunately, you're brain hasn't exploded.

    So, this function adds users and groups to a *local* group.

    If the members are already part of the group, nothing happens.

    The user running this function must have access to the directory where each principal in the `Member` parameter and the directory where each of the group's current members are located.

    .EXAMPLE
    Add-GroupMember -Name Administrators -Member EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Adds Darth Vader, Emperor Palpatine and Luke Skywalker to the local administrators group.

    .EXAMPLE
    Add-GroupMember -Name TieFighters -Member NetworkService

    Adds the local NetworkService account to the local TieFighters group.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The group name.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The users/groups to add to a group.
		[Alias('Members')]
        $Member
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    [DirectoryServices.AccountManagement.GroupPrincipal]$group = Get-Group -Name $Name
    if( -not $group )
    {
        return
    }
    
    try
    {
        foreach( $_member in $Member )
        {
            $identity = Resolve-Identity -Name $_member
            if( -not $identity )
            {
                continue
            }

            if( (Test-GroupMember -GroupName $group.Name -Member $_member) )
            {
                continue
            }

            Write-Verbose -Message ('[{0}] Members       -> {1}' -f $Name,$identity.FullName)
            if( -not $PSCmdlet.ShouldProcess(('adding ''{0}'' to local group ''{1}''' -f $identity.FullName, $group.Name), $null, $null) )
            {
                continue
            }

            try
            {
                $identity.AddToLocalGroup( $group.Name )
            }
            catch
            {
                Write-Error ('Failed to add ''{0}'' to group ''{1}'': {2}.' -f $identity,$group.Name,$_)
            }
        }
    }
    finally
    {
        $group.Dispose()
    }
}

Set-Alias -Name 'Add-GroupMembers' -Value 'Add-GroupMember'

