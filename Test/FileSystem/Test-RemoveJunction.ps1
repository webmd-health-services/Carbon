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

function SetUp
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $JunctionPath = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Junction $JunctionPath $TestDir
}

function TearDown
{
    if( Test-Path $JunctionPath -PathType Container )
    {
        cmd /c rmdir $JunctionPath
    }
    Remove-Module Carbon
}

function Invoke-RemoveJunction($junction)
{
    Remove-Junction $junction
}

function Test-ShouldRemoveJunction
{
    Invoke-RemoveJunction $JunctionPath
    Assert-DirectoryDoesNotExist $JunctionPath 'Failed to delete junction.'
    Assert-DirectoryExists $TestDir
}

function Test-ShouldDoNothingIfJunctionActuallyADirectory
{
    $realDir = Join-Path $env:Temp ([IO.Path]::GetRandomFileName())
    New-Item $realDir -ItemType 'Directory'
    $error.Clear()
    Invoke-RemoveJunction $realDir 2> $null
    Assert-DirectoryExists $realDir 'Real directory was removed.'
    Assert-Equal 1 $error.Count "Didn't write out any errors."
    Remove-Item $realDir
}

function Test-ShouldDoNothingIfJunctionActuallyAFile
{
    $path = [IO.Path]::GetTempFileName()
    $error.Clear()
    Invoke-RemoveJunction $path 2> $null
    Assert-FileExists $path 'File was deleted'
    Assert-Equal 1 $error.Count "Didn't write out any errors."
    Remove-Item $path
}

function Test-ShouldSupportWhatIf
{
    Remove-Junction -Path $JunctionPath -WhatIf
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
        Remove-Junction -Path ".\$junctionName"
        Assert-DirectoryDoesNotExist $JunctionPath 'Failed to delete junction with relative path.'
        Assert-DirectoryExists $TestDir
    }
    finally
    {
        Pop-Location
    }
}