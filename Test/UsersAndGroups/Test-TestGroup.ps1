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

function Start-Test
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Stop-Test
{
}

function Test-ShouldCheckIfLocalGroupExists
{
    $groups = Get-Group
    try
    {
        Assert-NotNull $groups
        $groups | ForEach-Object { Assert-True (Test-Group -Name $_.Name) }
    }
    finally
    {
        $groups | ForEach-Object { $_.Dispose() }
    }
}

function Test-ShouldNotFindNonExistentAccount
{
    $error.Clear()
    Assert-False (Test-Group -Name ([Guid]::NewGuid().ToString().Substring(0,20)))
    Assert-False $error
}
