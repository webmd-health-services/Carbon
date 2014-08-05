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

. (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Security\ConvertTo-ProviderAccessControlRights.ps1' -Resolve)

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Test-ShouldConvertFileSystemValue
{
    Assert-Equal ([Security.AccessControl.FileSystemRights]::Read) (ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read')
}

function Test-ShouldConvertFileSystemValues
{
    $expected = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Write
    $actual = ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read','Write'
    Assert-Equal $expected $actual
}

function Test-ShouldConvertFileSystemValueFromPipeline
{
    $expected = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Write
    $actual = 'Read','Write' | ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem'
    Assert-Equal $expected $actual
}

function Test-ShouldConvertRegistryValue
{
    $expected = [Security.AccessControl.RegistryRights]::Delete
    $actual = 'Delete' | ConvertTo-ProviderAccessControlRights -ProviderName 'Registry'
    Assert-Equal $expected $actual
}

function Test-ShouldHandleInvalidRightName
{
    $Error.Clear()
    Assert-Null (ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'BlahBlah','Read' -ErrorAction 'SilentlyContinue')
    Assert-Equal 1 $Error.Count
}