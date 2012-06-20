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
    Assert-Equal $group1.SID $group2.SID 'A new group was created!'
    
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
