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

function SetUp()
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown()
{
    Remove-Module Carbon
}

function Test-GetPathRelativeToWithExplicitPath
{
    $fileDir = New-TempDir
    $to = Join-Path $fileDir 'myfile.txt'
    
    $from = [System.IO.Path]::GetTempPath()
    
    $relativePath = Get-PathRelativeTo $from -To $to
    Assert-Equal ".\$([System.IO.Path]::GetFileName($fileDir))\myfile.txt" $relativePath 
}

function Test-GetPathRelativeToFromPipeline
{
    $to = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\..\Carbon\FileSystem.ps1') )
    
    $relativePath = Get-Item $to | Get-PathRelativeTo $TestDir
    Assert-Equal '..\..\Carbon\FileSystem.ps1' $relativePath
}

function Test-GetsPathFromFilePath
{
    $to = [System.IO.Path]::GetFullPath( (Join-Path $TestDir '..\..\Carbon\FileSystem.ps1') )
    
    $relativePath = Get-Item $to | Get-PathRelativeTo $TestScript 'File'
    Assert-Equal '..\..\Carbon\FileSystem.ps1' $relativePath
}

function Test-GetsRelativePathForMultiplePaths
{

    Get-ChildItem $env:WinDir | Get-PathRelativeTo -From (Join-Path $env:WinDir 'System32') 
}

function Test-GetsRelativePathFromFile
{
    $relativePath = Get-PathRelativeTo 'C:\Foo\Foo\Foo.txt' 'File' -To 'C:\Bar\Bar\Bar'
    Assert-Equal '..\..\Bar\Bar\Bar' $relativePath
}

function Test-ShouldReturnString
{
    $relativePath = Get-PathRelativeTo 'C:\A\B\C' -To 'C:\A\B\D\f.txt'
    Assert-Is $relativePath string
    Assert-Equal '..\D\F.txt' $relativePath
}
