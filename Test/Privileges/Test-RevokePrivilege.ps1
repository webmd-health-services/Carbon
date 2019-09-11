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

$username = 'CarbonRevokePrivileg' 
$password = 'a1b2c3d4#'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -Username $username -Password $password -Description 'Account for testing Carbon Revoke-Privileges functions.'
    
    Grant-Privilege -Identity $username -Privilege 'SeBatchLogonRight'
    Assert-True (Test-Privilege -Identity $username -Privilege 'SeBatchLogonRight')
}

function Stop-Test
{
    Uninstall-User -Username $username
}

function Test-ShouldNotRevokePrivilegeForNonExistentUser
{
    $error.Clear()
    Revoke-Privilege -Identity 'IDNOTEXIST' -Privilege SeBatchLogonRight -ErrorAction SilentlyContinue
    Assert-True ($error.Count -gt 0)
    Assert-True ($error[0].Exception.Message -like '*Identity * not found*')
}

function Test-ShouldNotBeCaseSensitive
{
    Revoke-Privilege -Identity $username -Privilege SEBATCHLOGONRIGHT
    Assert-False (Test-Privilege -Identity $username -Privilege SEBATCHLOGONRIGHT)
    Assert-False (Test-Privilege -Identity $username -Privilege SeBatchLogonRight)
}

function Test-ShouldRevokeNonExistentPrivilege
{
    $Error.Clear()
    Assert-False (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
    Revoke-Privilege -Identity $username -Privilege SeServiceLogonRight
    Assert-Equal 0 $Error.Count
    Assert-False (Test-Privilege -Identity $username -Privilege SeServiceLogonRight)
}

