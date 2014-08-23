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

$PSCommandPath = $MyInvocation.MyCommand.Definition

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    $PSCommandName = Split-Path -Leaf -Path $PSCommandPath
    $tempDir = New-TempDir -Prefix $PSCommandName
    $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
    Compress-Item -Path $PSScriptRoot -OutFile $zipPath
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
}

function Test-ShouldDetectZipFile
{
    Assert-True (Test-ZipFile -Path $zipPath)
}

function Test-ShouldTestNonZipFile
{
    Assert-False (Test-ZipFile -Path $PSCommandPath)
}

function Test-ShouldTestWithRelativePath
{
    Push-Location $env:windir
    try
    {
        $relativePath = Resolve-RelativePath -Path $zipPath -FromDirectory (Get-Location).ProviderPath
        Assert-True (Test-ZipFile -Path $relativePath)
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldTestNonExistentFile
{
    Assert-Null (Test-ZipFile -Path 'kablooey.zip' -ErrorAction SilentlyContinue)
    Assert-Error -Last -Regex 'not found'
}
