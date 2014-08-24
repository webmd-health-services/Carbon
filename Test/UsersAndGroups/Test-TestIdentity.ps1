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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldFindLocalGroup
{
    Assert-True (Test-Identity -Name 'Administrators')
}


function Test-ShouldFindLocalUser
{
    Assert-True (Test-Identity -Name 'Administrator')
}

function Test-ShouldFindDomainUser
{
    Assert-True (Test-Identity -Name ('{0}\Administrator' -f $env:USERDOMAIN))
}

function Test-ShouldReturnSecurityIdentifier
{
    $sid = Test-Identity -Name 'Administrator' -PassThru
    Assert-NotNull $sid
    Assert-True ($sid -is [Carbon.Identity])
}

function Test-ShouldNotFindMissingLocalUser
{
    $error.Clear()
    Assert-False (Test-Identity -Name 'IDoNotExistIHope')
    Assert-Equal 0 $error.Count
}

function Test-ShouldNotFindMissingLocalUserWithComputerForDomain
{
    $error.Clear()
    Assert-False (Test-Identity -Name ('{0}\IDoNotExistIHope' -f $env:COMPUTERNAME))
    Assert-Equal 0 $error.Count
}

function Test-ShouldNotFindUserInBadDomain
{
    $error.Clear()
    Assert-False (Test-Identity -Name 'MISSINGDOMAIN\IDoNotExistIHope' -ErrorAction SilentlyContinue)
    Assert-Equal 0 $error.Count
}

function Test-ShouldNotFindUserInCurrentDomain
{
    $error.Clear()
    Assert-False (Test-Identity -Name ('{0}\IDoNotExistIHope' -f $env:USERDOMAIN) -ErrorAction SilentlyContinue)
    Assert-Equal 0 $error.Count
}

function Test-ShouldFindUserWithDotDomain
{
    $users = Get-User
    Assert-NotNull $users
    $foundAUser = $false
    foreach( $user in $users )
    {
        Assert-True (Test-Identity -Name ('.\{0}' -f $user.SamAccountName))
        $foundAUser = $true
    }
    Assert-True $foundAUser
}

function Test-ShouldFindLocalSystem
{
    Assert-True (Test-Identity -Name 'LocalSystem')
}