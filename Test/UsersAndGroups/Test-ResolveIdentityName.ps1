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
    $fullName = Resolve-IdentityName -Name 'Administrators'
    Assert-Equal 'BUILTIN\Administrators' $fullName
}

function Test-ShouldResolveNTAuthorityIdentity
{
    $fullName = Resolve-IdentityName -Name 'NetworkService'
    Assert-Equal 'NT AUTHORITY\NETWORK SERVICE' $fullName
}

function Test-ShouldNotResolveMadeUpName
{
    $fullName = Resolve-IdentityName -Name 'IDONotExist'
    Assert-Null $fullName
}

function Test-ShouldResolveNameWithDotPrefix
{
    $id = Resolve-IdentityName -Name '.\Administrator'
    Assert-NoError
    Assert-NotNull $id
    Assert-Equal ('{0}\Administrator' -f $env:COMPUTERNAME) $id
}