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
$password = 'IM33tRequ!rem$'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    Remove-TestUser
}

function Stop-Test
{
    Remove-TestUser
}

function Remove-TestUser
{
    Uninstall-User -Username $username
}

function Test-ShouldCreateNewUser
{
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    $user = Install-User -Username $username -Password $password -Description $description -FullName $fullName
    Assert-NotNull $user
    Assert-Is $user ([DirectoryServices.AccountManagement.UserPrincipal])
    Assert-True (Test-User -Username $username)
    [DirectoryServices.AccountManagement.UserPrincipal]$user = Get-User -Username $username
    Assert-NotNull $user
    Assert-Equal $description $user.Description
    Assert-False $user.PasswordNeverExpires 
    Assert-True $user.Enabled
    Assert-Equal $username $user.SamAccountName
    Assert-False $user.UserCannotChangePassword
    Assert-Equal $fullName $user.DisplayName
    Assert-Credential -Password $password
}

function Test-ShouldUpdateExistingUsersProperties
{
    $fullName = 'Carbon Install User'
    Install-User -Username $username -Password $password -Description "Original description" -FullName $fullName
    $originalUser = Get-User -Username $username
    Assert-NotNull $originalUser
    
    $newFullName = 'New {0}' -f $fullName
    $newDescription = "New description"
    $newPassword = [Guid]::NewGuid().ToString().Substring(0,14)
    Install-User -Username $username `
                 -Password $newPassword `
                 -Description $newDescription `
                 -FullName $newFullName `
                 -UserCannotChangePassword `
                 -PasswordNeverExpires 

    [DirectoryServices.AccountManagement.UserPrincipal]$newUser = Get-User -Username $username
    Assert-NotNull $newUser
    Assert-Equal $originalUser.SID $newUser.SID
    Assert-Equal $newDescription $newUser.Description
    Assert-Equal $newFullName $newUser.DisplayName
    Assert-True $newUser.PasswordNeverExpires
    Assert-True $newUser.UserCannotChangePassword
    Assert-Credential -Password $newPassword
}

function Test-ShouldAllowOptionalFullName
{
    $fullName = 'Carbon Install User'
    $description = "Test user for testing the Carbon Install-User function."
    Install-User -Username $username -Password $password -Description $description
    $user = Get-User -Username $Username
    Assert-Null $user.DisplayName
}

function Test-ShouldSupportWhatIf
{
    $user = Install-User -Username $username -Password $password -WhatIf
    Assert-NotNull $user
    $user = Get-User -Username $username -ErrorAction SilentlyContinue
    Assert-Null $user
}

function Assert-Credential
{
    param(
        $Password
    )
    $ctx = [DirectoryServices.AccountManagement.ContextType]::Machine
    $px = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' $ctx,$env:COMPUTERNAME
    Assert-True ($px.ValidateCredentials( $username, $password ))
}
