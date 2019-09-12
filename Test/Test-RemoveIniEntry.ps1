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

Describe 'Test-RemoveIniEntry' {
    BeforeAll {
        & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
    }
    
    BeforeEach {
        $iniPath = Join-Path ([IO.Path]::GetTempPath()) ([IO.Path]::GetRandomFileName())
        $null = New-Item $iniPath -ItemType File
        @'
sectionless = value
section1value1 = duplicate

[section1]
section1value1 = value2
unicodevalue = ����������

'@ | Set-Content -Path $iniPath
        $Global:Error.Clear()
    }
    
    AfterEach {
        Remove-Item $iniPath
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

        $iniPath | Should Exist

        $actualContents = @( Get-Content $iniPath )
        $actualContents.Length | Should Be $expectedLines.Length
        for( $idx = 0; $idx -lt $actualContents.Length; ++$idx )
        {
            $actualContents[$idx] | Should Be $expectedLines[$idx]
        }
    }
    
    It 'should not remove entry that does not exist' {
        $originalIniFile = ((Get-Content -Path $iniPath) -join "`r`n")
    
        Remove-IniEntry -Path $iniPath -Section section -Name empty 
        $Error.Count | Should Be 0
        Assert-IniFile $originalIniFile
    }
    
    It 'should support what if' {
        $Error.Clear()
        $originalIniFile = ((Get-Content -Path $iniPath) -join "`r`n")
    
        Remove-IniEntry -Path $iniPath -Section section1 -Name section1value1 -WhatIf
        $Error.Count | Should Be 0
        Assert-IniFile $originalIniFile
    }
    
    It 'should remove sectionless entry' {
        Remove-IniEntry -Path $iniPath -Name section1value1
    
    Assert-IniFile @'
sectionless = value

[section1]
section1value1 = value2
unicodevalue = ����������

'@
    }
    
    It 'should remove entry in section' {
        Remove-IniEntry -Path $iniPath -Name section1value1 -Section section1
    
    Assert-IniFile @'
sectionless = value
section1value1 = duplicate

[section1]
unicodevalue = ����������

'@
    }
    
    It 'should remove case sensitive ini options' {
        @'
name = a
NAME = b

[section]
name = c

[SECTION]
name = d

'@ | Set-Content -Path $iniPath
    
        Remove-IniEntry -Path $iniPath -Name 'name' -CaseSensitive
        Remove-IniEntry -Path $iniPath -Section 'section' -Name 'name' -CaseSensitive
    
        $ini = Split-Ini -Path $iniPath -CaseSensitive -AsHashtable
        $ini | Should Not BeNullOrEmpty
        $ini.Count | Should Be 2
        $ini['NAME'].Value | Should Be 'b'
        $ini['SECTION.name'].Value | Should Be 'd'
    
    }

    It 'should remove last entry from a file when it is the only line' {

        # Regression. Make sure there is only one line in the file for test to catch it.
@'
MyKey = a
'@ | Set-Content -Path $iniPath

        Remove-IniEntry -Path $iniPath -Name 'MyKey'

        $ini = Split-Ini -Path $iniPath -AsHashtable
        $ini.Count | Should Be 0
    }
}
