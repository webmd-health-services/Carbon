# Copyright 2012 Aaron Jensen
# 
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
    
    [DirectoryServices.AccountManagement.GroupPrincipal]$group = Get-Group -Name $Name
    if( -not $group )
    {
        return
    }
    
    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    
    $changesMade = $false
    $Member | 
        ForEach-Object { Resolve-Identity -Name $_ } |
        ForEach-Object {
            $identity = $_
            $ctxType = 'Domain'
            $ctxName = $identity.Domain
            if( $identity.Domain -eq $env:COMPUTERNAME -or $identity.Domain -eq 'BUILTIN' -or $identity.Domain -eq 'NT AUTHORITY' )
            {
                $ctxName = $env:COMPUTERNAME
                $ctxType = 'Machine'
            }
            $identityCtx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctxType,$ctxName

            $notAMember = -not $group.Members.Contains( $identityCtx, 'Sid', $identity.Sid.Value )
            if( $notAMember -and $pscmdlet.ShouldProcess( $group.Name, ("add member {0}" -f $identity.FullName) ) )
            {
            	try
            	{
                    $group.Members.Add( $identityCtx, 'Sid', $identity.Sid.Value )
                    $changesMade = $true
                }
                catch
                {
                    Write-Error ('Failed to add ''{0}'' to group ''{1}'': {2}.' -f $identity,$Name,$_)
                }
            }
        }

    if( $changesMade )
    {
        try
        {
            $group.Save()
        }
        catch
        {
            Write-Error ('Failed to save changes to group ''{0}'': {1}.' -f $Name,$_)
        }
    }
}

Set-Alias -Name 'Add-GroupMembers' -Value 'Add-GroupMember'
