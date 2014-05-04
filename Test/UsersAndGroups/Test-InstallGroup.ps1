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

$GroupName = 'Setup Group'
$userName = 'CarbonTestUser'
$password = '1M33tRequirement$'
$description = 'Carbon user for use in Carbon tests.'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    Install-User -Username $userName -Password $password -Description $description
    Remove-Group
}

function Stop-Test
{
    Remove-Group
}

function Remove-Group
{
    $group = Get-Group |
                Where-Object { $_.Name -eq $GroupName }
    if( $group -ne $null )
    {
        net localgroup `"$GroupName`" /delete
    }
}

function Invoke-NewGroup($Description = '', $Members = @())
{
    $group = Install-Group -Name $GroupName -Description $Description -Members $Members
    Assert-NotNull $group 'Install-Group didn''t return the created/updated group.'
    Assert-GroupExists
    $expectedGroup = Get-Group -Name $GroupName
    Assert-Equal $group.Sid $expectedGroup.Sid
}

function Test-ShouldCreateGroup
{
    $expectedDescription = 'Hello, wordl!'
    Invoke-NewGroup -Description $expectedDescription
    $group = Get-Group -Name $GroupName
    Assert-NotNull $group
    Assert-Equal $GroupName $group.Name
    Assert-Equal $expectedDescription $group.Description 'Group not created with a description.'
}

function Test-ShouldAddMembers
{
    Invoke-NewGroup -Members $userName
    
    $details = net localgroup `"$GroupName`"
    Assert-ContainsLike $details $userName ('{0} not added to group.' -f $userName)
}

function Test-ShouldNotRecreateIfGroupAlreadyExists
{
    Invoke-NewGroup -Description 'Description 1'
    $group1 = Get-Group -Name $GroupName
    
    Invoke-NewGroup -Description 'Description 2'
    $group2 = Get-Group -Name $GroupName
    
    Assert-Equal 'Description 2' $group2.Description 'Description not changed/updated.'
    Assert-Equal $group1.SID $group2.SID 'A new group was created!'
    
}

function Test-ShouldNotAddMemberMultipleTimes
{
    Invoke-NewGroup -Members $userName
    
    $Error.Clear()
    Invoke-NewGroup -Members $userName
    Assert-Equal 0 $Error.Count
}

function Test-ShouldAddMemberWithLongName
{
    Invoke-NewGroup -Members 'WBMD\WHS - Lifecycle Services'
    $details = net localgroup `"$GroupName`"
    Assert-ContainsLike $details 'WBMD\WHS - Lifecycle Services' 'Lifecycle Services not added to group.'
}

function Test-ShouldSupportWhatIf
{
    $Error.Clear()
    $group = Install-Group -Name $GroupName -WhatIf -Member 'Administrator'
    Assert-Equal 0 $Error.Count
    Assert-NotNull $group
    $group = Get-Group -Name $GroupName -ErrorAction SilentlyContinue
    Assert-Null $group
}

function Assert-GroupExists
{
    $group = Get-Group |
                Where-Object { $_.Name -eq $GroupName }
    Assert-NotNull $group 'Group not created.'
}
