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

$tempDir = $null
$childDir = $null
$grandchildFile = $null
$childFile = $null

function Start-TestFixture 
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDirectoryTree @'
+ ChildDir
  * GrandchildFile
* ChildFile
'@
    $childDir = Join-Path $tempDir 'ChildDir' -Resolve
    $grandchildFile = Join-Path $tempDir 'ChildDir\GrandchildFile' -Resolve
    $childFile = Join-Path $tempDir 'ChildFile' -Resolve

    Enable-NtfsCompression $tempDir -Recurse

    Assert-EverythingCompressed
}

function Stop-Test
{
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Test-ShouldDisableCompressionOnDirectoryOnly
{
    Disable-NtfsCompression -Path $tempDir

    Assert-NotCompressed -Path $tempDir
    Assert-Compressed -Path $childDir
    Assert-Compressed -path $grandchildFile
    Assert-Compressed -Path $childFile

    $newFile = Join-Path $tempDir 'newfile'
    '' > $newFile
    Assert-NotCompressed -Path $newFile

    $newDir = Join-Path $tempDir 'newDir'
    $null = New-Item -Path $newDir -ItemType Directory
    Assert-NotCompressed -Path $newDir
}

function Test-ShouldFailIfPathDoesNotExist
{
    $Error.Clear()

    Disable-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue

    Assert-Equal 1 $Error.Count
    Assert-True ($Error[0].Exception.Message -like '*not found*')

    Assert-EverythingCompressed
}

function Test-ShouldDisableCompressionRecursively
{
    Disable-NtfsCompression -Path $tempDir -Recurse

    Assert-NothingCompressed
}

function Test-ShouldSupportPipingItems
{
    Get-ChildItem $tempDir | Disable-NtfsCompression

    Assert-Compressed $tempDir
    Assert-NotCompressed $childDir
    Assert-Compressed $grandchildFile
    Assert-NotCompressed $childFile
}

function Test-ShouldSupportPipingStrings
{
    ($childFile,$grandchildFile) | Disable-NtfsCompression

    Assert-Compressed $tempDir
    Assert-Compressed $childDir
    Assert-NotCompressed $grandchildFile
    Assert-NotCompressed $childFile
}

function Test-ShouldDecompressArrayOfItems
{
    Disable-NtfsCompression -Path $childFile,$grandchildFile
    Assert-Compressed $tempDir
    Assert-Compressed $childDir
    Assert-NotCompressed $grandchildFile
    Assert-NotCompressed $childFile
}

function Test-ShouldDecompressAlreadyDecompressedItem
{
    Disable-NtfsCompression $tempDir -Recurse
    Assert-NothingCompressed

    Disable-NtfsCompression $tempDir -Recurse
    Assert-LastProcessSucceeded
    Assert-NothingCompressed
}

function Test-ShouldSupportWhatIf
{
    Disable-NtfsCompression -Path $childFile -WhatIf
    Assert-Compressed $childFile
}

function Assert-EverythingCompressed
{
    Assert-Compressed -Path $tempDir
    Assert-Compressed -Path $childDir
    Assert-Compressed -Path $grandchildFile
    Assert-Compressed -Path $childFile
}

function Assert-NothingCompressed
{
    Assert-NotCompressed -Path $tempDir
    Assert-NotCompressed -Path $childDir
    Assert-NotCompressed -Path $grandchildFile
    Assert-NotCompressed -Path $childFile
}

function Assert-Compressed
{
    param(
        $Path
    )

    Assert-True (Test-NtfsCompression -Path $Path) ('{0} is not compressed' -f $Path)
}

function Assert-NotCompressed
{
    param(
        $Path
    )
    Assert-False (Test-NtfsCompression -Path $Path) ('{0} is compressed' -f $Path)
}