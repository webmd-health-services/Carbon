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

$iniPath = $null

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    $iniPath = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
    $null = New-Item $iniPath -ItemType File
    @'
sectionless = value
section1value1 = duplicate

[section1]
section1value1 = value2

'@ > $iniPath
}

function Stop-Test
{
    Remove-Item $iniPath
}

function Test-ShouldNotRemoveEntryThatDoesNotExist
{
    $Error.Clear()
    $originalIniFile = ((Get-Content -Path $iniPath) -join "`r`n")

    Remove-IniEntry -Path $iniPath -Section section -Name empty 
    Assert-Equal 0 $Error.Count
    Assert-IniFile $originalIniFile
}

function Test-ShouldSupportWhatIf
{
    $Error.Clear()
    $originalIniFile = ((Get-Content -Path $iniPath) -join "`r`n")

    Remove-IniEntry -Path $iniPath -Section section1 -Name section1value1 -WhatIf
    Assert-Equal 0 $Error.Count
    Assert-IniFile $originalIniFile
}

function Test-ShouldRemoveSectionlessEntry
{
    Remove-IniEntry -Path $iniPath -Name section1value1

    Assert-IniFile @'
sectionless = value

[section1]
section1value1 = value2

'@
}

function Test-ShouldRemoveEntryInSection
{
    Remove-IniEntry -Path $iniPath -Name section1value1 -Section section1

    Assert-IniFile @'
sectionless = value
section1value1 = duplicate

[section1]

'@
}

function Assert-IniFile
{
    param(
        [string]
        $ExpectedContents
    )
    
    $expectedLines = @()
    if( $ExpectedContents )
    {
        $expectedLines = $ExpectedContents -split "`r`n"
    }
    Assert-FileExists $iniPath
    $actualContents = @( Get-Content $iniPath )
    Assert-Equal $expectedLines.Length $actualContents.Length "Number of lines in file not equal."
    for( $idx = 0; $idx -lt $actualContents.Length; ++$idx )
    {
        Assert-Equal $expectedLines[$idx] $actualContents[$idx] "line $idx"
    }
}
