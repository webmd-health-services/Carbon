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

function Add-GroupMembers
{
    <#
    .SYNOPSIS
    Adds a users or groups to a *local* group.

    .DESCRIPTION
    You would think it's pretty easy and straight-forward to add users/groups to a local group, but you would be wrong.  The quick solution is to use `net localgroup`, but that won't accept user/group names longer than 24 characters.  This means you have to use the .NET Directory Services APIs.  How do you reliably add both users *and* groups?  What if those users are in a domain?  What if they're in another domain?  What about built-in users?  Fortunately, you're brain hasn't exploded.

    So, this function adds users and groups to a *local* group.

    If the members are already part of the group, nothing happens.

    .EXAMPLE
    Add-GroupMembers -Name Administrators -Members EMPIRE\DarthVader,EMPIRE\EmperorPalpatine,REBELS\LSkywalker

    Adds Darth Vader, Emperor Palpatine and Luke Skywalker to the local administrators group.

    .EXAMPLE
    Add-GroupMembers -Name TieFighters -Members NetworkService

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
        $Members
    )

    $Builtins = @{ 
                    'NetworkService' = 'NT AUTHORITY\NETWORK SERVICE'; 
                    'Administrators' = 'Administrators'; 
                    'ANONYMOUS LOGON' = 'NT AUTHORITY\ANONYMOUS LOGON'; 
                 }
    
    $group = [adsi]('WinNT://{0}/{1}' -f $env:ComputerName,$Name)
    if( $group -eq $null )
    {
        Write-Error "Active directory is unable to find local group $group."
        return
    }

    $currentMembers = net localgroup `"$Name`"
    $Members |
        Where-Object { $currentMembers -notcontains $_ } |
        ForEach-Object {
            $member = $_
            if( $Builtins.ContainsKey( $member ) )
            {
                $canonicalMemberName = $Builtins[$member]
                if( $currentMembers -contains $canonicalMemberName )
                {
                    continue
                }
                if( $pscmdlet.ShouldProcess( $Name, "add built-in member $member" ) )
                {
                    Write-Host "Adding $member to group $Name."
                    net localgroup $Name $member /add
                }
            }
            else
            {
                $memberPath = 'WinNT://{0}/{1}' -f $env:ComputerName,$member
                if( $member.Contains("\") )
                {
                    $memberPath = 'WinNT://{0}/{1}' -f ($member -split '\\')
                }
                
                if( $pscmdlet.ShouldProcess( $Name, "add member $member" ) )
                {
                    Write-Host "Adding $member to group $Name."
                    [void] $group.Add( $memberPath )
                }
            }
        }
}
