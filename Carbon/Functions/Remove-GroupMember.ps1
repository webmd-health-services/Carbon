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

function Remove-GroupMember
{
    <#
    .SYNOPSIS
    Removes users or groups from a *local* group.

    .DESCRIPTION
    You would think it's pretty easy and straight-forward to remove users/groups from a local group, but you would be wrong.  The quick solution is to use `net localgroup`, but that won't accept user/group names longer than 24 characters.  This means you have to use the .NET Directory Services APIs.  How do you reliably remove both users *and* groups?  What if those users are in a domain?  What if they're in another domain?  What about built-in users?  Fortunately, your brain hasn't exploded.

    So, this function removes users or groups from a *local* group.

    If the user or group is not a member, nothing happens.

    `Remove-GroupMember` is new in Carbon 2.0.

    .EXAMPLE
    Remove-GroupMember -Name Administrators -Member EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Removes Darth Vader, Emperor Palpatine and Luke Skywalker from the local administrators group.

    .EXAMPLE
    Remove-GroupMember -Name TieFighters -Member NetworkService

    Removes the local NetworkService account from the local TieFighters group.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The group name.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The users/groups to remove from a group.
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

            if( -not (Test-GroupMember -GroupName $group.Name -Member $_member) )
            {
                continue
            }

            Write-Verbose -Message ('[{0}] Members      {1} ->' -f $Name,$identity.FullName)
            if( -not $PSCmdlet.ShouldProcess(('removing ''{0}'' from local group ''{1}''' -f $identity.FullName, $group.Name), $null, $null) )
            {
                continue
            }

            try
            {
                $identity.RemoveFromLocalGroup( $group.Name )
            }
            catch
            {
                Write-Error ('Failed to remove ''{0}'' from local group ''{1}'': {2}.' -f $identity,$group.Name,$_)
            }
        }
    }
    finally
    {
        $group.Dispose()
    }
}

