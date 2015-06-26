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

function Test-ShouldResolveBuiltinIdentity
{
    $identity = Resolve-IdentityName -Name 'Administrators'
    Assert-Equal 'BUILTIN\Administrators' $identity
}

function Test-ShouldResolveNTAuthorityIdentity
{
    $identity = Resolve-IdentityName -Name 'NetworkService'
    Assert-Equal 'NT AUTHORITY\NETWORK SERVICE' $identity
}

function Test-ShouldResolveEveryone
{
    $identity  = Resolve-IdentityName -Name 'Everyone'
    Assert-Equal 'Everyone' $identity
}

function Test-ShouldNotResolveMadeUpName
{
    $fullName = Resolve-IdentityName -Name 'IDONotExist'
    Assert-NoError
    Assert-Null $fullName
}

function Test-ShouldResolveLocalSystem
{
    Assert-Equal 'NT AUTHORITY\SYSTEM' (Resolve-IdentityName -Name 'localsystem')
}

function Test-ShouldResolveDotAccounts
{
    foreach( $user in (Get-User) )
    {
        $id = Resolve-IdentityName -Name ('.\{0}' -f $user.SamAccountName)
        Assert-Equal ('{0}\{1}' -f $env:COMPUTERNAME,$user.SamAccountName) $id
    }
}
