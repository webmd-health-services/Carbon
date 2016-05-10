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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

Describe 'Carbon_IniFile' {
    $testConfigName = 'CarbonIniFileOption'
    $tempDir = $null
    $iniPath = $null
    $sectionName = $null
    $defaultValue = $null
    $defaultValue2 = $null

    function Assert-IniFile
    {
        param(
            $Section,
    
            $Name = $testConfigName,
    
            [Parameter(Position=0)]
            $Value,
    
            [Switch]
            $CaseSensitive = $false
        )
    
        Set-StrictMode -Version 'Latest'
    
        $ini = Split-Ini -Path $iniPath -AsHashtable -CaseSensitive:$CaseSensitive
    
        $key = $Name
        if( $Section )
        {
            $key = '{0}.{1}' -f $Section,$Name
        }
    
        if( $Value -eq $null )
        {
            ($ini.ContainsKey( $key )) | Should Be $false
        }
        else
        {
            ($ini.ContainsKey( $key )) | Should Be $true
            $ini[$key].Value | Should Be $Value
        }
    }

    BeforeAll {
        Start-CarbonDscTestFixture 'IniFile'
    }
    
    BeforeEach {
        $Global:Error.Clear()

        $tempDir = New-TempDir -Prefix $PSCommandPath
        $iniPath = Join-Path -Path $tempDir -ChildPath 'ini'
        $defaultValue = [Guid]::NewGuid().ToString()
        $defaultValue2 = [Guid]::NewGuid().ToString()
        $sectionName = [Guid]::NewGuid().ToString()
        $null = New-Item -Path $iniPath -ItemType 'File'
        @'
prefix = {0}

[{1}]
prefix = {2}
'@ -f $defaultValue,$sectionName,$defaultValue2 | Set-Content -Path $iniPath
    }
    
    AfterEach {
        Remove-Item -Path $tempDir -Recurse
    }
    
    AfterAll {
        Stop-CarbonDscTestFixture
    }

    It 'should get config value' {
        $value = Get-TargetResource -Path $iniPath -Name 'prefix'
        $value | Should Not BeNullOrEmpty
        $value.Path | Should Be $iniPath
        'prefix' | Should Be $value.Name
        $value.Value | Should Be $defaultValue
        $value.CaseSensitive | Should Be $false
        $value.Force | Should Be $false
        Assert-IniFile -Name 'prefix' -Value $value.Value
        Assert-DscResourcePresent $value
    }
    
    It 'should get section config value' {
        $value = Get-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix'
        $value | Should Not BeNullOrEmpty
        $value.Section | Should Be $sectionName
        $value.Name | Should Be 'prefix'
        $value.Value | Should Be $defaultValue2
        Assert-IniFile -Section $sectionName -Name 'prefix' -Value $value.Value
        Assert-DscResourcePresent $value
    }
    
    It 'should pass along case sensitive and force args' {
        $value = Get-TargetResource -Path $iniPath -Name 'prefix' -CaseSensitive -Force
        $value.CaseSensitive | Should Be $true
        $value.Force | Should Be $true
    }
    
    It 'should get missing config value' {
        $value = Get-TargetResource -Path $iniPath -Name 'fubar'
        $value | Should Not BeNullOrEmpty
        $value.Value | Should BeNullOrEmpty
        Assert-DscResourceAbsent $value
    }
    
    It 'should throw error if path does not exist' {
        $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
        $bogusPath | Should Not Exist
        $value = Get-TargetResource -Path $bogusPath -Name 'prefix' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
        $value | Should BeNullOrEmpty
    }
    
    It 'should be absent if path does not exist and force' {
        $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
        $bogusPath | Should Not Exist
        $value = Get-TargetResource -Path $bogusPath -Name 'prefix' -Force
        $Global:Error.Count | Should Be 0
        $value | Should Not BeNullOrEmpty
        $value.Path | Should Be $bogusPath
    }
    
    It 'should test config' {
        (Test-TargetResource -Path $iniPath -Name 'prefix' -Value (Get-TargetResource -Path $iniPath -Name 'prefix').Value) | Should Be $true
        (Test-TargetResource -Path $iniPath -Name 'prefix' -Value 'C:\I\Do\Not\Exist') | Should Be $false
    }
    
    It 'test missing config' {
        (Test-TargetResource -Path $iniPath -Name 'fubar' -Value 'fubar' -Ensure 'Absent') | Should Be $true
        (Test-TargetResource -Path $iniPath -Name 'fubar' -Value 'fubar') | Should Be $false
    }
    
    It 'should test missing ini path' {
        $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
        $bogusPath | Should Not Exist
        (Test-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue -ErrorAction SilentlyContinue) | Should Be $false
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not foun'
        $Error.Clear()
        (Test-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue -Force) | Should Be $false
        $Global:Error.Count | Should Be 0
    }
    
    It 'should test value in section' {
        (Test-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Value $defaultValue2) | Should Be $true
        (Test-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Value $defaultValue) | Should Be $false
    }
    
    It 'should setup config' {
        $name = 'CarbonIniFile'
        $value = [Guid]::NewGuid().ToString()
    
        Set-TargetResource -Path $iniPath -Name $name -Value $value
        Assert-IniFile -Name $name -Value $value
    
        $newValue = [guid]::NewGuid().ToString()
        Set-TargetResource -Path $iniPath -Name $name -Value $newValue
        Assert-IniFile -Name $name -Value $newValue 
    
        Set-TargetResource -Path $iniPath -Name $name -Ensure 'Absent'
        (Get-TargetResource -Path $iniPath -Name $name).Value | Should BeNullOrEmpty
    }
    
    It 'should treat name as case sensitive' {
        $value1 = [Guid]::NewGuid()
        $value2 = [Guid]::NewGuid()
    
        Set-TargetResource -Path $iniPath -Name $testConfigName -Value $value1 -CaseSensitive
        Set-TargetResource -Path $iniPath -Name $testConfigName.ToUpper() -Value $value2 -CaseSensitive
    
        Assert-IniFile -Name $testConfigName -Value $value1 -CaseSensitive
        Assert-IniFile -Name $testConfigName.ToUpper() -Value $value2 -CaseSensitive
    }
    
    It 'should treat value as case sensitive' {
        $value1 = 'fubar'
    
        Set-TargetResource -Path $iniPath -Name $testConfigName -Value $value1
        (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1 -CaseSensitive) | Should Be $true
        (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1.ToUpper()) | Should Be $true
        (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1.ToUpper() -CaseSensitive) | Should Be $false
    }
    
    It 'should not create missing ini file' {
        $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
        $bogusPath | Should Not Exist
        Set-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue2 -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'not found'
        $bogusPath | Should Not Exist
    }
    
    It 'should create missing ini file' {
        $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogusParent\bogusFile'
        $bogusPath | Should Not Exist
        Set-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue2 -Force
        $Global:Error.Count | Should Be 0
        $bogusPath | Should Exist
        $ini = Split-Ini -Path $bogusPath -AsHashtable
        $ini.ContainsKey('prefix') | Should Be $true
        $ini['prefix'].Value | Should Be $defaultValue2
    }
    
    It 'should set value in section' {
        $newValue = [Guid]::NewGuid().ToString()
        Set-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Value $newValue
        Assert-IniFile -Section $sectionName -Name 'prefix' -Value $newValue
    }
    
    It 'should remove value in section' {
        Set-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Ensure Absent
        $ini = Split-Ini -Path $iniPath -AsHashtable
        $ini.ContainsKey( ('{0}.prefix' -f $sectionName) ) | Should Be $false
        $ini.ContainsKey('prefix') | Should Be $true
    }
    
    configuration DscConfiguration
    {
        param(
            $Value,
            $Ensure = 'Present'
        )
    
        Set-StrictMode -Off
    
        Import-DscResource -Name '*' -Module 'Carbon'
    
        node 'localhost'
        {
            Carbon_IniFile set
            {
                Path = $iniPath;
                Name = $testConfigName
                Value = $Value;
                Ensure = $Ensure;
            }
        }
    }

    It 'should run through dsc' {
        $value = [Guid]::NewGuid().ToString()
    
        & DscConfiguration -Value $value -OutputPath $CarbonDscOutputRoot
    
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot  -Force
        $Global:Error.Count | Should Be 0
        Assert-IniFile $value 
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot  -Force
        $Global:Error.Count | Should Be 0
        Assert-IniFile $null

        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_IniFile' } | Should Not BeNullOrEmpty
    }
    
}
