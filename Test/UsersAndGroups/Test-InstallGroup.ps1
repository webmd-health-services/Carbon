
Import-Module (Join-Path $TestDir ..\..\Carbon) -Force

$GroupName = 'Setup Group'

function Setup
{
    Remove-Group
}

function TearDown
{
    Remove-Group
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

function Invoke-NewGroup($Description = '', $Members = @())
{
    Install-Group -Name $GroupName -Description $Description -Members $Members
    Assert-GroupExists
}

function Test-ShouldCreateGroup
{
    $expectedDescription = 'Hello, wordl!'
    Invoke-NewGroup -Description $expectedDescription
    $group = Get-Group
    Assert-Equal $expectedDescription $group.Description 'Group not created with a description.'
}

function Ignore-ShouldAddMembers
{
    Invoke-NewGroup -Members 'Administrators'
    
    $details = net localgroup `"$GroupName`"
    Assert-ContainsLike $details 'Administrators' 'Administrators not added to group.'
}

function Test-ShouldNotRecreateIfGroupAlreadyExists
{
    Invoke-NewGroup -Description 'Description 1'
    $group1 = Get-Group
    
    Invoke-NewGroup -Description 'Description 2'
    $group2 = Get-Group
    
    Assert-Equal 'Description 2' $group2.Description 'Description not changed/updated.'
    Assert-Equal $group1.SSID $group2.SSID 'A new group was created!'
    
}

function Ignore-ShouldNotAddMemberMultipleTimes
{
    Invoke-NewGroup -Members 'Administrators'
    
    Invoke-NewGroup -Members 'Administrators'
}

function Test-ShouldAddMemberWithLongName
{
    Invoke-NewGroup -Members 'WBMD\WHS - Lifecycle Services'
    $details = net localgroup `"$GroupName`"
    Assert-ContainsLike $details 'WBMD\WHS - Lifecycle Services' 'Lifecycle Services not added to group.'
}

function Assert-GroupExists
{
    $group = Get-Group
    Assert-NotNull $group 'Group not created.'
}