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

$username = 'CarbonInstallUser'
$password = [Guid]::NewGuid().ToString().Substring(0,14)

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Remove-TestUser
}

function TearDown
{
    Remove-TestUser
    Remove-Module Carbon
}

function Remove-TestUser
{
    Uninstall-User -Username $username
}

function Test-ShouldCreateNewUser
{
    $description = "Test user for testing the Carbon Install-User function."
    Install-User -Username $username -Password $password -Description $description
    Assert-True (Test-User -Username $username)
    $user = Get-WmiLocalUserAccount -Username $Username
    Assert-NotNull $user
    Assert-Equal $description $user.Description
    Assert-False $user.PasswordExpires 
}

function Test-ShouldUpdateExistingUsersProperties
{
    Install-User -Username $username -Password $password -Description "Original description"
    $originalUser = Get-WmiLocalUserAccount -Username $username
    Assert-NotNull $originalUser
    
    $newDescription = "New description"
    Install-User -Username $username -Password ([Guid]::NewGuid().ToString().Substring(0,14)) -Description $newDescription
    $newUser = Get-WmiLocalUserAccount -Username $username
    Assert-NotNull $newUser
    Assert-Equal $originalUser.SID $newUser.SID
    Assert-Equal $newDescription $newUser.Description
}

function Test-ShouldSupportWhatIf
{
    Install-User -Username $username -Password $password -WhatIf
    $user = Get-WmiLocalUserAccount -Username $username
    Assert-Null $user
}
