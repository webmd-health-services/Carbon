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

Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

function SetUp
{
}

function TearDown
{
}

function Invoke-TestPathIsJunction($path)
{
    return Test-PathIsJunction $path
}

function Test-ShouldKnowFilesAreNotReparsePoints
{
    $result = Test-PathIsJunction $TestScript
    Assert-False $result 'Detected a file as being a reparse point'
}

function Test-ShouldKnowDirectoriesAreNotReparsePoints
{
    $result = Invoke-TestPathIsJunction $TestDir
    Assert-False $result 'Detected a directory as being a reparse point'
}

function Test-ShouldDetectAReparsePoint
{
    $reparsePath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Junction $reparsePath $TestDir
    $result = Invoke-TestPathIsJunction $reparsePath
    Assert-True $result 'junction not detected'
    Remove-Junction $reparsePath
}

function Test-ShouldHandleNonExistentPath
{
    $result = Invoke-TestPathIsJunction ([IO.Path]::GetRandomFileName())
    Assert-False $result 'detected a non-existent junction'
    Assert-Equal 0 $error.Count 'there were errors detecting a non-existent junction'
}
