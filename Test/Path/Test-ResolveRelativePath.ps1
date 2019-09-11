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

function Test-ResolveRelativePathWithExplicitPath
{
    $fileDir = New-TempDir
    $to = Join-Path $fileDir 'myfile.txt'
    
    $from = [System.IO.Path]::GetTempPath()
    
    $relativePath = Resolve-RelativePath -Path $to -FromDirectory $from
    Assert-Equal ".\$([System.IO.Path]::GetFileName($fileDir))\myfile.txt" $relativePath 
}

function Test-ResolveRelativePathFromPipeline
{
    $to = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\..\Carbon\Import-Carbon.ps1') )
    
    $relativePath = Get-Item $to | Resolve-RelativePath -FromDirectory $TestDir
    Assert-Equal '..\..\Carbon\Import-Carbon.ps1' $relativePath
}

function Test-ResolvesPathPathFromFilePath
{
    $to = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\..\Carbon\Import-Carbon.ps1') )
    
    $relativePath = Get-Item $to | Resolve-RelativePath -FromFile $TestScript 
    Assert-Equal '..\..\Carbon\Import-Carbon.ps1' $relativePath
}

function Test-ResolvesPathForMultiplePaths
{
    Get-ChildItem $env:WinDir | 
        Resolve-RelativePath -FromDirectory (Join-Path $env:WinDir 'System32') |
        ForEach-Object {
            Assert-True $_.StartsWith( '..\' )
        }
}

function Test-ResolvesPathFromFile
{
    $relativePath = Resolve-RelativePath -Path 'C:\Bar\Bar\Bar' -FromFile 'C:\Foo\Foo\Foo.txt'
    Assert-Equal '..\..\Bar\Bar\Bar' $relativePath
}

function Test-ShouldReturnString
{
    $relativePath = Resolve-RelativePath -Path 'C:\A\B\D\f.txt' -FromDirectory 'C:\A\B\C' 
    Assert-Is $relativePath string
    Assert-Equal '..\D\F.txt' $relativePath
}

