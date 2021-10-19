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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)
. (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Functions\Use-CallerPreference.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param
    (
        [parameter(Mandatory = $true)]
        [System.String]
        $Name
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $group = Get-CGroup -Name $Name -ErrorAction Ignore

    $ensure = 'Absent'
    $description = $null
    $members = @()
    if( $group )
    {
        $description = $group.Description
        $members = $group.Members
        $ensure = 'Present'
    }

    @{
        Name = $Name
        Ensure = $ensure
        Description = $description
        Members = $members
    }
}

function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for configuring local Windows groups.

    .DESCRIPTION
    The `Carbon_Group` resource installs and uninstalls groups. It also adds members to existing groups. 
    
    The group is installed when `Ensure` is set to `Present`. Members of the group are updated to match the `Members` property (i.e. members not listed in the `Members` property are removed from the group). If `Members` has no value, all members are removed. Because DSC resources run under the LCM which runs as `System`, local system accounts must have access to the directories where both new and existing member accounts can be found.

    The group is removed when `Ensure` is set to `Absent`. When removing a group, the `Members` property is ignored.

    The `Carbon_Group` resource was added in Carbon 2.1.0.

    .LINK
    Add-CGroupMember

    .LINK
    Install-CGroup

    .LINK
    Remove-CGroupMember

    .LINK
    Test-CGroup

    .LINK
    Uninstall-CGroup

    .EXAMPLE
    >
    Demonstrates how to install a group and add members to it.

        Carbon_Group 'CreateFirstOrder'
        {
            Name = 'FirstOrder';
            Description = 'On to victory!';
            Ensure = 'Present';
            Members = @( 'FO\SupremeLeaderSnope', 'FO\KRen' );
        }

    .EXAMPLE
    >
    Demonstrates how to uninstall a group.

        Carbon_Group 'RemoveRepublic
        {
            Name = 'Republic';
            Ensure = 'Absent';
        }

    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param
    (
        [parameter(Mandatory=$true)]
        [string]
        # The name of the group.
        $Name,

        [string]
        # A description of the group. Only used when adding/updating a group (i.e. when `Ensure` is `Present`).
        $Description,

        [ValidateSet("Present","Absent")]
        [string]
        # Should be either `Present` or `Absent`. If set to `Present`, a group is configured and membership configured. If set to `Absent`, the group is removed.
        $Ensure,

        [string[]]
        # The group's members. Only used when adding/updating a group (i.e. when `Ensure` is `Present`).
        #
        # Members not in this list are removed from the group.
        $Members = @()
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $Ensure -eq 'Absent' )
    {
        Uninstall-CGroup -Name $Name
        return
    }

    $group = Install-CGroup -Name $Name -Description $Description -Member $Members -PassThru
    if( -not $group )
    {
        return
    }

    try
    {
        $memberNames = @()
        if( $Members )
        {
             $memberNames = $Members | Resolve-MemberName
        }
        $membersToRemove = $group.Members | Where-Object {
                                                            $memberName = Resolve-PrincipalName -Principal $_
                                                            return $memberNames -notcontains $memberName
                                                         }
        if( $membersToRemove )
        {
            foreach( $memberToRemove in $membersToRemove )
            {
                Write-Verbose -Message ('[{0}] Members      {1} ->' -f $Name,(Resolve-PrincipalName -Principal $memberToRemove))
                $group.Members.Remove( $memberToRemove )
            }

            if( $PSCmdlet.ShouldProcess( ('local group {0}' -f $Name), 'remove members' ) )
            {
                $group.Save()
            }
        }
    }
    finally
    {
        $group.Dispose()
    }
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    param
    (
        [parameter(Mandatory = $true)]
        [string]
        $Name,

        [string]
        $Description = $null,

        [ValidateSet("Present","Absent")]
        [string]
        $Ensure = "Present",

        [string[]]
        $Members = @()
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $resource = Get-TargetResource -Name $Name

    # Do we need to delete the group?
    if( $Ensure -eq 'Absent' -and $resource.Ensure -eq 'Present' )
    {
        Write-Verbose -Message ('[{0}] Group is present but should be absent.' -f $Name)
        return $false
    }

    # Is it already gone?
    if( $Ensure -eq 'Absent' -and $resource.Ensure -eq 'Absent' )
    {
        return $true
    }

    # Do we need to create the group?
    if( $Ensure -eq 'Present' -and $resource.Ensure -eq 'Absent' )
    {
        Write-Verbose -Message ('[{0}] Group is absent but should be present.' -f $Name)
        return $false
    }

    # Is the group out-of-date?
    $upToDate = $true
    if( $Description -ne $resource.Description )
    {
        Write-Verbose -Message ('[{0}] [Description] ''{1}'' != ''{2}''' -f $Name,$Description,$resource.Description)
        $upToDate = $false
    }

    $memberNames = @()
    if( $Members )
    {
         $memberNames = $Members | Resolve-MemberName
    }
    $currentMemberNames = $resource['Members'] | Resolve-PrincipalName

    # Is the current group missing the desired members?
    foreach( $memberName in $memberNames )
    {
        if( $currentMemberNames -notcontains $memberName )
        {
            Write-Verbose -Message ('[{0}] [Members] {1} is absent but should be present' -f $Name,$memberName)
            $upToDate = $false
        }
    }

    # Does the current group contains extra members?
    foreach( $memberName in $currentMemberNames )
    {
        if( $memberNames -notcontains $memberName )
        {
            Write-Verbose -Message ('[{0}] [Members] {1} is present but should be absent' -f $Name,$memberName)
            $upToDate = $false
        }
    }

    return $upToDate
}

function Resolve-MemberName
{
    param(
        [Parameter(Mandatory=$true,VAlueFromPipeline=$true)]
        [string]
        $Name
    )

    process
    {
        Resolve-CIdentityName -Name $Name
    }
}

function Resolve-PrincipalName
{
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        $Principal
    )

    process
    {
        Resolve-CIdentity -SID $Principal.Sid.Value | Select-Object -ExpandProperty 'FullName'
    }
}

Export-ModuleMember -Function *-TargetResource

