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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -Credential (New-Credential -Username $userName -Password $password) -Description $description
    Remove-Group
}

function Stop-Test
{
    Remove-Group
}

function Remove-Group
{
    $groups = Get-Group 
    try
    {
        $group = $groups |
                    Where-Object { $_.Name -eq $GroupName }
        if( $group -ne $null )
        {
            net localgroup `"$GroupName`" /delete
        }
    }
    finally
    {
        $groups | ForEach-Object { $_.Dispose() }
    }
}

function Invoke-NewGroup($Description = '', $Members = @())
{
    $group = Install-Group -Name $GroupName -Description $Description -Members $Members -PassThru
    try
    {
        Assert-NotNull $group 'Install-Group didn''t return the created/updated group.'
        Assert-GroupExists
        $expectedGroup = Get-Group -Name $GroupName
        try
        {
            Assert-Equal $group.Sid $expectedGroup.Sid
        }
        finally
        {
            $expectedGroup.Dispose()
        }
    }
    finally
    {
        if( $group )
        {
            $group.Dispose()
        }
    }
}

function Test-ShouldCreateGroup
{
    $expectedDescription = 'Hello, wordl!'
    Invoke-NewGroup -Description $expectedDescription
    $group = Get-Group -Name $GroupName
    try
    {
        Assert-NotNull $group
        Assert-Equal $GroupName $group.Name
        Assert-Equal $expectedDescription $group.Description 'Group not created with a description.'
    }
    finally
    {
        $group.Dispose()
    }
}

function Test-ShouldPassThruGroup
{
    $group = Install-Group -Name $GroupName 
    try
    {
        Assert-Null $group
    }
    finally
    {
        if( $group )
        {
            $group.Dispose()
        }
    }

    $group = Install-Group -Name $GroupName -PassThru
    try
    {
        Assert-NotNull $group
        Assert-Is $group ([DirectoryServices.AccountManagement.GroupPrincipal])
    }
    finally
    {
        $group.Dispose()
    }
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
    try
    {
    
        Invoke-NewGroup -Description 'Description 2'
        $group2 = Get-Group -Name $GroupName
        
        try
        {
            Assert-Equal 'Description 2' $group2.Description 'Description not changed/updated.'
            Assert-Equal $group1.SID $group2.SID 'A new group was created!'
        }
        finally
        {
            $group2.Dispose()
        }
    }
    finally
    {
        $group1.Dispose()
    }    
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
    $longUsername = 'abcdefghijklmnopqrst' 
    Install-User -Credential (New-Credential -Username $longUsername -Password 'a1b2c34d!')
    try
    {
        Invoke-NewGroup -Members ('{0}\{1}' -f $env:COMPUTERNAME,$longUsername)
        $details = net localgroup `"$GroupName`"
        Assert-ContainsLike $details $longUsername ('{0} not added to group.' -f $longUsername)
    }
    finally
    {
        Uninstall-User -Username $userName
    }
}

function Test-ShouldSupportWhatIf
{
    $Error.Clear()
    $group = Install-Group -Name $GroupName -WhatIf -Member 'Administrator'
    try
    {
        Assert-NoError
        Assert-Null $group
    }
    finally
    {
        if( $group )
        {
            $group.Dispose()
        }
    }

    $group = Get-Group -Name $GroupName -ErrorAction SilentlyContinue
    try
    {
        Assert-Null $group
    }
    finally
    {
        if( $group )
        {
            $group.Dispose()
        }
    }
}

function Assert-GroupExists
{
    $groups = Get-Group
    try
    {
        $group = $groups |
                    Where-Object { $_.Name -eq $GroupName }
        Assert-NotNull $group 'Group not created.'
    }
    finally
    {
        $groups | ForEach-Object { $_.Dispose() }
    }
}

