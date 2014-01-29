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

$username = 'CarbonRemoveUser'
$password = 'IM33tRequ!rement$'

function Start-Test
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
    net user $username $password /add /Y
    Assert-True (Test-User -Username $username)
}

function Stop-Test
{
    if( Test-User -Username $username )
    {
        net user $username /delete
    }
}

function Test-ShouldRemoveUser
{
    Uninstall-User -Username $username
    Assert-False (Test-User -Username $username)
}

function Test-ShouldHandleRemovingNonExistentUser
{
    $Error.Clear()
    Uninstall-User -Username ([Guid]::NewGuid().ToString().Substring(0,20))
    Assert-False $Error
}

function Test-ShouldSupportWhatIf
{
    Uninstall-User -Username $username -WhatIf
    Assert-True (Test-User -Username $username)
}
