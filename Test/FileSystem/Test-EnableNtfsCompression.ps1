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
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
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
}

function Stop-Test
{
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Test-ShouldEnableCompressionOnDirectoryOnly
{
    Assert-NothingCompressed
    
    Enable-NtfsCompression -Path $tempDir

    Assert-Compressed -Path $tempDir
    Assert-NotCompressed -Path $childDir
    Assert-NotCompressed -path $grandchildFile
    Assert-NotCompressed -Path $childFile

    $newFile = Join-Path $tempDir 'newfile'
    '' > $newFile
    Assert-Compressed -Path $newFile

    $newDir = Join-Path $tempDir 'newDir'
    $null = New-Item -Path $newDir -ItemType Directory
    Assert-Compressed -Path $newDir
}

function Test-ShouldFailIfPathDoesNotExist
{
    $Error.Clear()

    Assert-NothingCompressed

    Enable-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue

    Assert-Equal 1 $Error.Count
    Assert-True ($Error[0].Exception.Message -like '*not found*')

    Assert-NothingCompressed
}

function Test-ShouldEnableCompressionRecursively
{
    Assert-NothingCompressed
    
    Enable-NtfsCompression -Path $tempDir -Recurse

    Assert-EverythingCompressed
}

function Test-ShouldSupportPipingItems
{
    Assert-NothingCompressed 

    Get-ChildItem $tempDir | Enable-NtfsCompression

    Assert-NotCompressed $tempDir
    Assert-Compressed $childDir
    Assert-NotCompressed $grandchildFile
    Assert-Compressed $childFile
}

function Test-ShouldSupportPipingStrings
{
    ($childFile,$grandchildFile) | Enable-NtfsCompression

    Assert-NotCompressed $tempDir
    Assert-NotCompressed $childDir
    Assert-Compressed $grandchildFile
    Assert-Compressed $childFile
}

function Test-ShouldCompressArrayOfItems
{
    Enable-NtfsCompression -Path $childFile,$grandchildFile
    Assert-NotCompressed $tempDir
    Assert-NotCompressed $childDir
    Assert-Compressed $grandchildFile
    Assert-Compressed $childFile
}

function Test-ShouldCompressAlreadyCompressedItem
{
    Enable-NtfsCompression $tempDir -Recurse
    Assert-EverythingCompressed

    Enable-NtfsCompression $tempDir -Recurse
    Assert-LastProcessSucceeded
    Assert-EverythingCompressed
}

function Test-ShouldSupportWhatIf
{
    Enable-NtfsCompression -Path $childFile -WhatIf
    Assert-NotCompressed $childFile
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