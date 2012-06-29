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

	function Find-UserOrGroup
	{
		[CmdletBinding()]
		param(
			# The user or group name
			$Name
		)

		$shortName = $Name
		$containerName = $env:ComputerName
		$container = [adsi] "WinNT://$containerName,computer"
		if( $Name.Contains("\") )
		{
			$domain,$shortName = $Name -split '\',2,'SimpleMatch'
			
			$domainController = Get-ADDomainController -Domain $domain
			$container = [adsi] ('WinNT://{0}' -f $domainController)
			$containerName = $domain
		}

		if( -not $container )
		{
			Write-Error "Unable to find container for '$Name'."
			return $null
		}
		
		try
		{
			$user = $container.Children.Find($shortName, "User")
			return [adsi]"WinNT://$containerName/$shortName"
		}
		catch
		{
		}
		
		try
		{
			$group = $container.Children.Find($shortName, "Group")
			return [adsi]"WinNT://$containerName/$shortName,group"
		}
		catch
		{
		}
		
		return $null
	}
    
    $Builtins = @{ 
                    'NetworkService' = 'NT AUTHORITY\NETWORK SERVICE'; 
                    'Administrators' = 'Administrators'; 
                    'ANONYMOUS LOGON' = 'NT AUTHORITY\ANONYMOUS LOGON'; 
                 }
    
    $group = Find-UserOrGroup $Name
    if( $group -eq $null )
    {
        throw "Active directory is unable to find local group $group."
    }

    $currentMembers = net localgroup `"$Name`"
    foreach( $member in $Members )
    {
        if( $currentMembers -contains $member )
        {
            continue
        }
        
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
            $adMember = Find-UserOrGroup -Name $member
            if( -not $adMember )
            {
                Write-Error "Unable to find user '$member'."
                continue
            }
            
            if( $pscmdlet.ShouldProcess( $Name, "add member $member" ) )
            {
                Write-Host "Adding $($adMember.Name) to group $Name."
                [void] $group.Add( $adMember.Path )
            }
        }
    }
}

function Get-WmiLocalUserAccount
{
    <#
    .SYNOPSIS
    Gets a WMI `Win32_UserAccount` object for a *local* user account.

    .DESCRIPTION
    Man, there are so many ways to get a user account in Windows.  This function uses WMI to get a local user account.  It returns a `Win32_UserAccount` object.  The username has to be less than 20 characters.  We don't remember why anymore, but it's probaly a restriction of WMI.  Or Windows.  Or both.

    You can do this with `Get-WmiObject`, but when you try to get a `Win32_UserAccount`, PowerShell reaches out to your domain and gets all the users it finds, even if you filter by name.  This is slow!  This function stops WMI from talking to your domain, so it is faster.

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa394507(v=vs.85).aspx

    .EXAMPLE
    Get-WmiLocalUserAccount -Username Administrator

    Gets the local Administrator account as a `Win32_UserAccount` WMI object.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(0,20)]
        [string]
        # The username of the local user to get.
        $Username
    )
    
    return Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)' and Name='$Username'"
}

function Install-Group
{
    <#
    .SYNOPSIS
    Creates a new local group, or updates the settings for an existing group.

    .DESCRIPTION
    Creates a new group with a description and default set of members.  If a group with the same name already exists, it updates the group's description and adds the given members to it.

    .EXAMPLE
    Install-Group -Name TIEFighters -Description 'Users allowed to be TIE fighter pilots.' -Members EMPIRE\Pilots,EMPIRE\DarthVader

    If the TIE fighters group doesn't exist, it is created with the given description and default members.  If it already exists, its description is updated and the given members are added to it.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the group.
        $Name,
        
        [string]
        # A description of the group.
        $Description = '',
        
        [string[]]
        # Members of the group.
        $Members = @()
    )
    
    $group = Get-WmiObject Win32_Group -Filter "Name='$Name' and LocalAccount = True"
    $addArg =  ''
    $action = 'Updating'
    if( -not $group ) 
    {
        $action = "Creating" 
        $addArg = "/ADD" 
    } 
    Write-Host "$action local group '$Name'."
    
    net localgroup `"$Name`" /Comment:"$Description" $addArg
    
    if( $Members )
    {
        Add-GroupMembers -Name $Name -Members $Members
    }
}

function Install-User
{
    <#
    .SYNOPSIS
    Installs a *local* user account.

    .DESCRIPTION
    Creates a new *local* user account, or, if the account already exists, updates its password and description.  In both cases, the users password is set to never expire.  This should probably be a parameter.  Send us a patch! 

    .EXAMPLE
    Install-User -Username LSkywalker -Password "whydidn'tyoutellme" -Description "Luke Skywalker's account."

    Creates a new `LSkywalker` user account with the given password and description.  Luke's password is set ot never expire.  
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username for the user.
        $Username,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user's password.
        $Password,
        
        [Parameter()]
        [string]
        # A description of the user.
        $Description
    )
    
    $userExists = Test-User -Username $username
    $operation = 'update'
    $logAction = 'Updating'
    $addArg = ''
    if( -not $userExists )
    {
        $addArg = '/ADD'
        $operation = 'create'
        $logAction = 'Creating'
    }
    
    if( $pscmdlet.ShouldProcess( $Username, "$operation local user" ) )
    {
        Write-Host "$logAction local user $Username."
        net user $Username $Password $addArg /Comment:$Description
        
        if( -not $userExists )
        {
            $user = Get-WmiLocalUserAccount -Username $Username
            $user.PasswordExpires = $false
            $user.Put()
        }
    }
}

function Remove-User
{
    <#
    .SYNOPSIS
    Removes a user from the local computer.

    .DESCRIPTION
    Removes a *local* user account.  If the account doesn't exist, nothing happens.

    .EXAMPLE
    Remove-User -Username WTarkin

    Removes the `WTarkin` *local* user account.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username of the account to remove.
        $Username
    )
    
    if( Test-User -Username $username )
    {
        if( $pscmdlet.ShouldProcess( "$Username", "remove local user" ) )
        {
            net user $Username /delete
        }
    }
}

function Test-User
{
    <#
    .SYNOPSIS
    Checks if a user account exists.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(1,20)]
        [string]
        # The username of the account to check
        $Username
    )

    $user = Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)' and Name='$Username'"
    return ($user -ne $null)

}

