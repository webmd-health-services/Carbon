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

$JunctionPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $JunctionPath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Junction $JunctionPath $TestDir
}

function Stop-Test
{
    if( Test-Path $JunctionPath -PathType Container )
    {
        cmd /c rmdir $JunctionPath
    }
}

function Invoke-UninstallJunction($junction)
{
    Uninstall-Junction $junction
}

function Test-ShouldUninstallJunction
{
    Invoke-UninstallJunction $JunctionPath
    Assert-NoError
    Assert-DirectoryDoesNotExist $JunctionPath 'Failed to delete junction.'
    Assert-DirectoryExists $TestDir
}

function Test-ShouldFailIfJunctionActuallyADirectory
{
    $realDir = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Item $realDir -ItemType 'Directory'
    $error.Clear()
    Invoke-UninstallJunction $realDir 2> $null
    Assert-Error -Last -Regex 'is a directory'
    Assert-DirectoryExists $realDir 'Real directory was removed.'
    Remove-Item $realDir
}

function Test-ShouldFailIfJunctionActuallyAFile
{
    $path = [IO.Path]::GetTempFileName()
    $error.Clear()
    Invoke-UninstallJunction $path 2> $null
    Assert-Error -Last -Regex 'is a file'
    Assert-FileExists $path 'File was deleted'
    Remove-Item $path
}

function Test-ShouldSupportWhatIf
{
    Uninstall-Junction -Path $JunctionPath -WhatIf
    Assert-DirectoryExists $JunctionPath
    Assert-FileExists (Join-Path $JunctionPath Test-RemoveJunction.ps1)
    Assert-DirectoryExists $TestDir
}

function Test-ShouldRemoveJunctionWithRelativePath
{
    $parentDir = Split-Path -Parent -Path $JunctionPath
    $junctionName = Split-Path -Leaf -Path $JunctionPath
    Push-Location $parentDir
    try
    {
        Uninstall-Junction -Path ".\$junctionName"
        Assert-DirectoryDoesNotExist $JunctionPath 'Failed to delete junction with relative path.'
        Assert-DirectoryExists $TestDir
    }
    finally
    {
        Pop-Location
    }
}
