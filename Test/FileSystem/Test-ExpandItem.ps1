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
$zipPath = $null
$outputRoot = $null
$PSCommandName = 'Test-ExpandItem.ps1'
$PSCommandPath = $MyInvocation.MyCommand.Definition

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $tempDir = New-TempDir -Prefix ('Carbon+{0}' -f $PSCommandName)
    $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
    Compress-Item -Path $PSCommandPath -OutFile $zipPath

    $outputRoot = Join-Path -Path $tempDir -ChildPath 'OutputRoot'
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
}

function Test-ShouldFailIfFileNotAZipFile
{
    $outputRoot = Expand-Item -Path $PSScriptRoot -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not a ZIP file'
    Assert-Null $outputRoot
}

function Test-ShouldExpandWithRelativePathToZip
{
    Push-Location -Path $env:windir
    try
    {
        $relativePath = Resolve-Path -Relative -Path $zipPath
        $result = Expand-Item -Path $relativePath -OutDirectory $outputRoot
        Assert-NoError
        Assert-NotNull $result
        Assert-FileExists (Join-Path -Path $outputRoot -ChildPath $PSCommandName)
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldExpandWithRelativePathToOutput
{
    Push-Location -Path $env:windir
    try
    {
        New-Item -Path $outputRoot -ItemType 'Directory'
        $relativePath = Resolve-Path -Relative -Path $outputRoot
        $result = Expand-Item -Path $zipPath -OutDirectory $relativePath
        Assert-NoError
        Assert-NotNull $result
        Assert-FileExists (Join-Path -Path $outputRoot -ChildPath $PSCommandName)
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldCreateOutputDirectory
{
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot
    Assert-DirectoryExists $result.FullName
    Assert-DirectoryExists $outputRoot
}

function Test-ShouldCarryOnIfOutputDirectoryIsEmpty
{
    New-Item -Path $outputRoot -ItemType 'Directory'
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot
    Assert-Equal $outputRoot $result.FullName
    Assert-NoError 
    Assert-Equal 1 @(Get-ChildItem $outputRoot).Count
}

function Test-ShouldStopIfOutputDirectoryNotEmpty
{
    New-Item -Path $outputRoot -ItemType 'Directory'
    $filePath = Join-Path -Path $outputRoot -ChildPath 'fubar'
    New-Item -Path $filePath -ItemType 'File'
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot -ErrorAction SilentlyContinue
    Assert-Null $result
    Assert-Error -Last -Regex 'not empty'
    Assert-Equal '' ([IO.File]::ReadAllText( $filePath ))
}

function Test-ShouldReplaceOutputDirectoryWithForceFlag
{
    New-Item -Path $outputRoot -ItemType 'Directory'
    $fubarPath = Join-Path -Path $outputRoot -ChildPath 'fubar'
    New-Item -Path $fubarPath -ItemType 'File'
    $filePath = Join-Path -Path $outputRoot -ChildPath $PSCommandName
    New-Item -Path $filePath -ItemType 'File'
    $result = Expand-Item -Path $zipPath -OutDirectory $outputRoot -Force
    Assert-NoError
    Assert-Equal $outputRoot $result.FullName
    Assert-NotNull ([IO.File]::ReadAllText( $filePath ))
}

function Test-ShouldNotExtractNonExistentFile
{
    $result = Expand-Item -Path 'C:\fubar.zip' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'does not exist'
    Assert-Null $result
}
