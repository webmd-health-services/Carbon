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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $PSCommandName = Split-Path -Leaf -Path $PSCommandPath
    $tempDir = New-TempDir -Prefix $PSCommandName
    $zipPath = Join-Path -Path $tempDir -ChildPath ('{0}.zip' -f $PSCommandName)
    Compress-Item -Path $PSCommandPath -OutFile $zipPath
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
    $tempDir2 = New-TempDirectory -Prefix $PSCommandPath
    Push-Location $tempDir2
    try
    {
        $relativePath = Resolve-RelativePath -Path $zipPath -FromDirectory (Get-Location).ProviderPath
        Assert-True (Test-ZipFile -Path $relativePath)
    }
    finally
    {
        Pop-Location
        Remove-Item -Path $tempDir2 -Recurse
    }
}

function Test-ShouldTestNonExistentFile
{
    Assert-Null (Test-ZipFile -Path 'kablooey.zip' -ErrorAction SilentlyContinue)
    Assert-Error -Last -Regex 'not found'
}

