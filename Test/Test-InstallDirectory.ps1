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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$root = $env:TEMP

function Test-ShouldCreateDirectory
{
    $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
    Assert-DirectoryDoesNotExist $dir
    Install-Directory -Path $dir
    try
    {
        Assert-NoError
        Assert-DirectoryExists $dir
    }
    finally
    {
        Remove-Item $dir
    }
}

function Test-ShouldHandleExistingDirectory
{
    $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
    Assert-DirectoryDoesNotExist $dir
    Install-Directory -Path $dir
    try
    {
        Install-Directory -Path $dir
        Assert-NoError
        Assert-DirectoryExists $dir
    }
    finally
    {
        Remove-Item $dir
    }
}

function Test-ShouldCreateMissingParents
{
    $dir = Join-Path -Path $root -ChildPath ([IO.Path]::GetRandomFileName())
    $dir = Join-Path -Path $dir -ChildPath ([IO.Path]::GetRandomFileName())
    Assert-DirectoryDoesNotExist $dir
    Install-Directory -Path $dir
    try
    {
        Assert-NoError
        Assert-DirectoryExists $dir
    }
    finally
    {
        Remove-Item $dir
    }
}