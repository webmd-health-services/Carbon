
$GroupName = 'AddMemberToGroup'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force

    Install-Group -Name $GroupName -Description "Group for testing the Add-MemberToGroup Carbon function."
}

function TearDown
{
    Remove-Group
    Remove-Module Carbon
}

function Remove-Group
{
    $group = Get-Group
    if( $group -ne $null )
    {
        net localgroup `"$GroupName`" /delete
    }
}

function Get-Group
{
    return Get-WmiObject Win32_Group -Filter "Name='$GroupName' and LocalAccount=True"
}

function Get-LocalUsers
{
    return Get-WmiObject Win32_UserAccount -Filter "LocalAccount=True"
}

function Invoke-AddMembersToGroup($Members = @())
{
    Add-MembersToGroup -Name $GroupName -Member $Members
    Assert-MembersInGroup -Member $Members
}

function Test-ShouldAddMemberFromDomain
{
    Invoke-AddMembersToGroup -Members 'WBMD\WHS - Lifecycle Services' 
}

function Test-ShouldAddLocalUser
{
    $users = Get-LocalUsers
    if( -not $users )
    {
        Fail "This computer has no local user accounts."
    }
    $addedAUser = $false
    foreach( $user in $users )
    {
        try
        {
            Invoke-AddMembersToGroup -Members $user.Name
            $addedAUser = $true
            break
        }
        catch
        {
        }
    }
    Assert-True $addedAuser
}

function Test-ShouldAddMultipleMembers
{
    $users = Get-LocalUsers
    $members = @( $users[0].Name, 'WBMD\WHS - Lifecycle Services' )
    Invoke-AddMembersToGroup -Members $members
}

function Test-ShouldSupportShouldProcess
{
    Add-MembersToGroup -Name $GroupName -Members 'WBMD\WHS - Lifecycle Services' -WhatIf
    $details = net localgroup $GroupName
    foreach( $line in $details )
    {
        Assert-False ($details -like '*WBMD\WHS - Lifecycle Services*')
    }
}

function Test-ShouldAddNetworkService
{
    Add-MembersToGroup -Name $GroupName -Members 'NetworkService'
    $details = net localgroup $GroupName
    Assert-ContainsLike $details 'NT AUTHORITY\Network Service'
}

function Assert-MembersInGroup($Members)
{
    $group = Get-Group
    Assert-NotNull $group 'Group not created.'
    $details = net localgroup $GroupName
    foreach( $member in $Members )
    {
        Assert-ContainsLike $details $member 
    }
}