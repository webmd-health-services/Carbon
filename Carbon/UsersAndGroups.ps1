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

function Add-MembersToGroup
{
    <#
    .SYNOPSIS
    Adds a users or groups to a  group.
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
    
    $Builtins = @{ 'NetworkService' = $true }
    
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
        
        if( $pscmdlet.ShouldProcess( $Name, "add member $member" ) )
        {
            if( $Builtins.ContainsKey( $member ) )
            {
                net localgroup $Name $member /add
            }
            else
            {
                $adMember = Find-UserOrGroup -Name $member
                if( -not $adMember )
                {
                    throw "Unable to find user '$member'."
                }
                Write-Host "Adding $($adMember.Name) to group $Name."
                [void] $group.Add( $adMember.Path )
            }
        }
    }
}

function Get-User
{
    <#
    .SYNOPSIS
    Gets the given user account.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [ValidateLength(0,20)]
        [string]
        $Username
    )
    
    return Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)' and Name='$Username'"
}

function Find-UserOrGroup
{
    [CmdletBinding()]
    param(
        # The user or group name
        $Name
    )

    $shortName = $Name
    $container = [adsi] "WinNT://$($env:ComputerName),computer"
    if( $Name.Contains("\") )
    {
        $parts = $Name -split '\',2,'SimpleMatch'
        $domain = $parts[0]
        $shortName = $parts[1]
        
        $domainController = Get-ADDomainController -Domain $domain
        $container = [adsi] ('WinNT://{0}' -f $domainController)
    }

    if( -not $container )
    {
        Write-Error "Unable to find container for '$Name'."
        return $null
    }
    
    try
    {
        return $container.Children.Find($shortName, "User")
    }
    catch
    {
        $entry = $null
    }
    
    if( $entry -eq $null )
    {
        try
        {
            return $container.Children.Find($shortName, "Group")
        }
        catch
        {
            return $null
        }
    }
}

function Install-Group
{
    <#
    .SYNOPSIS
    Creates a new local group.
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
        Add-MembersToGroup -Name $Name -Members $Members
    }
}

function Install-User
{
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
            $user = Get-User -Username $Username
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

