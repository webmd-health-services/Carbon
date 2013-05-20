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
$compressedDir = $null
$compressedFile = $null
$uncompressedDir = $null
$uncompressedFile = $null

function Setup
{
    $tempDir = New-TempDirectoryTree @'
+ CompressedDir
+ UncompressedDir
* CompressedFile
* UncompressedFile
'@
    $compressedDir = Join-Path $tempDir 'CompressedDir' -Resolve
    $compressedFile = Join-Path $tempDir 'CompressedFile' -Resolve
    $uncompressedDir = Join-Path $tempDir 'UncompressedDir' -Resolve
    $uncompressedFile = Join-Path $tempDir 'UncompressedFile' -Resolve

    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)

    Enable-NtfsCompression -Path $compressedDir
    Enable-NtfsCompression -Path $compressedFile
}

function TearDown
{
    if( (Test-Path -Path $tempDir -PathType Container) )
    {
        Remove-Item -Path $tempDir -Recurse
    }

    Remove-Module Carbon
}

function Test-ShouldDetectCompression
{
    Assert-True (Test-NtfsCompression -Path $compressedDir)
    Assert-True (Test-NtfsCompression -Path $compressedFile)
    Assert-False (Test-NtfsCompression -Path $uncompressedDir)
    Assert-False (Test-NtfsCompression -Path $uncompressedFile)
}

function Test-ShouldHandleBadPaths
{
    $Error.Clear()

    Assert-Null (Test-NtfsCompression -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue)

    Assert-Equal 1 $Error.Count
    Assert-True ($Error[0].Exception.Message -like '*not found*')
}