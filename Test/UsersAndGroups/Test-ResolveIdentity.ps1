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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Test-ShouldResolveBuiltinIdentity
{
    $identity = Resolve-IdentityName -Name 'Administrators'
    Assert-Equal 'BUILTIN\Administrators' $identity.FullName
    Assert-Equal 'BUILTIN' $identity.Domain
    Assert-Equal 'Administrators' $identity.Name
    Assert-NotNull $identity.Sid
    Assert-Equal 'Alias' $identity.Type
}

function Test-ShouldResolveNTAuthorityIdentity
{
    $identity = Resolve-IdentityName -Name 'NetworkService'
    Assert-Equal 'NT AUTHORITY\NETWORK SERVICE' $identity.FullName
    Assert-Equal 'NT AUTHORITY' $identity.Domain
    Assert-Equal 'NETWORK SERVICE' $identity.Name
    Assert-NotNull $identity.Sid
    Assert-Equal 'WellKnownGroup' $identity.Type
}

function Test-ShouldResolveEveryone
{
    $identity  = Resolve-IdentityName -Name 'Everyone'
    Assert-Equal 'Everyone' $identity.FullName
    Assert-Equal '' $identity.Domain
    Assert-Equal 'Everyone' $identity.Name
    Assert-NotNull $identity.Sid
    Assert-Equal 'WellKnownGroup' $identity.Type
}

function Test-ShouldNotResolveMadeUpName
{
    $Error.Clear()
    $fullName = Resolve-IdentityName -Name 'IDONotExist' -ErrorAction SilentlyContinue
    Assert-GreaterThan $Error.Count 0
    Assert-Like $Error[0].Exception.Message '*not found*'
    Assert-Null $fullName
}
