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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force
$UserName = 'CarbonDscTestUser'
$Password = [Guid]::NewGuid().ToString()

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'LocalUser'
}

function Start-Test
{
    Remove-TestUser
}

function Stop-Test
{
    Remove-TestUser
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldCreateAndUpdateUser
{
    $password = [Guid]::NewGuid().ToString()
    Set-TargetResource -UserName $UserName -Password $password -Ensure 'Present'
    $user = Get-User -Username $UserName
    Assert-NotNull $user
    Assert-Equal $UserName $user.SamAccountName
    Assert-Null $user.Description
    Assert-Null $user.DisplayName
    Assert-False $user.UserCannotChangePassword
    Assert-False $user.PasswordNeverExpires

    Set-TargetResource -UserName $UserName -Password $password -Description 'description' -FullName 'full name' -UserCannotChangePassword -PasswordNeverExpires -Ensure Present

    $user = Get-User -Username $UserName
    Assert-NotNull $user
    Assert-Equal $UserName $user.SamAccountName
    Assert-Equal 'description' $user.Description
    Assert-Equal 'full name' $user.DisplayName
    Assert-True $user.UserCannotChangePassword
    Assert-True $user.PasswordNeverExpires
}

function Test-ShouldRequirePasswordWhenCreatingUser
{
    Set-TargetResource -UserName $UserName -Ensure Present -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex ('password required')
    Assert-False (Test-User -Username $UserName)
}

function Test-ShouldRemoveUser
{
    Set-TargetResource -Username $UserName -Password ([Guid]::NewGuid()).ToString() -Ensure Present
    Assert-True (Test-User -Username $UserName)
    
    Set-TargetResource -Username $UserName -Ensure Absent
    Assert-False (Test-User -Username $UserName)
}

function Test-ShouldGetAbsentUser
{
    $resource = Get-TargetResource -Username $UserName
    Assert-NotNull $resource
    Assert-Equal $UserName $resource.UserName
    Assert-Empty $resource.Password
    Assert-Empty $resource.Description
    Assert-Empty $resource.FullName
    Assert-False $resource.UserCannotChangePassword
    Assert-False $resource.PasswordNeverExpires
    Assert-DscResourceAbsent $resource
}

function Test-ShouldGetUserWithDefaultsFromParameters
{
    $resource = Get-TargetResource -UserName $UserName -Password 'password' -Description 'description' -FullName 'Full Name' -UserCannotChangePassword -PasswordNeverExpires
    Assert-NotNull $resource
    Assert-Equal $UserName $resource.UserName
    Assert-Equal 'password' $resource.Password
    Assert-Equal 'description' $resource.Description
    Assert-Equal 'full name' $resource.FullName
    Assert-True $resource.UserCannotChangePassword
    Assert-True $resource.PasswordNeverExpires
    Assert-DscResourceAbsent $resource
}

function Test-ShouldGetExistingUser
{
    $value = ([Guid]::NewGuid().ToString())
    Set-TargetResource -UserName $UserName -Password $value -Description $value -FullName $value -UserCannotChangePassword -PasswordNeverExpires -Ensure Present
    Assert-True (Test-User -Username $UserName)

    $resource = Get-TargetResource -Username $UserName
    Assert-NotNull $resource
    Assert-Equal $UserName $resource.UserName
    Assert-Null $resource.Password
    Assert-Equal $value $resource.Description
    Assert-Equal $value $resource.FullName
    Assert-True $resource.UserCannotChangePassword
    Assert-True $resource.PasswordNeverExpires
    Assert-DscResourcePresent $resource
}

function Test-ShouldHandleMissingUser
{
    Assert-False (Test-TargetResource -Username $UserName -Ensure Present)
    Assert-True (Test-TargetResource -Username $UserName -Ensure Absent)
}

function Test-ShouldHandleExistingUser
{
    Set-TargetResource -UserName $UserName -Password ([Guid]::NewGuid().ToString()) -Ensure Present
    Assert-True (Test-TargetResource -Username $UserName -Ensure Present)
    Assert-False (Test-TargetResource -Username $UserName -Ensure Absent)
}

function Test-ShouldHandleChangedProperties
{
    $password = [Guid]::NewGuid().ToString()
    Set-TargetResource -UserName $UserName -Password $password -Ensure Present

    $testParams = @{ UserName = $UserName ; Password = $password ; Ensure = 'Present' }
    $newValue = [Guid]::NewGuid().ToString()
    Assert-False (Test-TargetResource @testParams -Description $newValue)
    Assert-False (Test-TargetResource @testParams -FullName $newValue)
    Assert-False (Test-TargetResource @testParams -UserCannotChangePassword)
    Assert-False (Test-TargetResource @testParams -PasswordNeverExpires)
    Assert-True (Test-TargetResource -Username $UserName -Password $newValue -Ensure Present)
}

configuration DscConfiguration
{
    param(
        $Ensure
    )

    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        LocalUser set
        {
            UserName = $UserName;
            Password = ([Guid]::NewGuid().ToString());
            Ensure = $Ensure;
        }
    }
}

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot 
    Assert-NoError
    Assert-True (Test-User -Username $UserName)

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot 
    Assert-NoError
    Assert-False (Test-User -Username $UserName)
}



function Remove-TestUser
{
    Uninstall-User -Username $UserName
}