
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

    $script:testConfigName = 'CarbonIniFileOption'
    $script:tempDir = $null
    $script:iniPath = $null
    $script:sectionName = $null
    $script:defaultValue = $null
    $script:defaultValue2 = $null

    function Assert-IniFile
    {
        param(
            $Section,

            $Name = $script:testConfigName,

            [Parameter(Position=0)]
            $Value,

            [Switch]
            $CaseSensitive = $false
        )

        Set-StrictMode -Version 'Latest'

        $ini = Split-CIni -Path $script:iniPath -AsHashtable -CaseSensitive:$CaseSensitive

        $key = $Name
        if( $Section )
        {
            $key = '{0}.{1}' -f $Section,$Name
        }

        if( $Value -eq $null )
        {
            ($ini.ContainsKey( $key )) | Should -BeFalse
        }
        else
        {
            ($ini.ContainsKey( $key )) | Should -BeTrue
            $ini[$key].Value | Should -Be $Value
        }
    }

    Start-CarbonDscTestFixture 'IniFile'
}

AfterAll {
    Stop-CarbonDscTestFixture
}

Describe 'Carbon_IniFile' {
    BeforeEach {
        $Global:Error.Clear()

        $script:tempDir = New-TempDir -Prefix $PSCommandPath
        $script:iniPath = Join-Path -Path $script:tempDir -ChildPath 'ini'
        $script:defaultValue = [Guid]::NewGuid().ToString()
        $script:defaultValue2 = [Guid]::NewGuid().ToString()
        $script:sectionName = [Guid]::NewGuid().ToString()
        $null = New-Item -Path $script:iniPath -ItemType 'File'
        @'
prefix = {0}

[{1}]
prefix = {2}
'@ -f $script:defaultValue,$script:sectionName,$script:defaultValue2 | Set-Content -Path $script:iniPath
    }

    AfterEach {
        Remove-Item -Path $script:tempDir -Recurse
    }

    It 'should get config value' {
        $value = Get-TargetResource -Path $script:iniPath -Name 'prefix'
        $value | Should -Not -BeNullOrEmpty
        $value.Path | Should -Be $script:iniPath
        'prefix' | Should -Be $value.Name
        $value.Value | Should -Be $script:defaultValue
        $value.CaseSensitive | Should -BeFalse
        $value.Force | Should -BeFalse
        Assert-IniFile -Name 'prefix' -Value $value.Value
        Assert-DscResourcePresent $value
    }

    It 'should get section config value' {
        $value = Get-TargetResource -Path $script:iniPath -Section $script:sectionName -Name 'prefix'
        $value | Should -Not -BeNullOrEmpty
        $value.Section | Should -Be $script:sectionName
        $value.Name | Should -Be 'prefix'
        $value.Value | Should -Be $script:defaultValue2
        Assert-IniFile -Section $script:sectionName -Name 'prefix' -Value $value.Value
        Assert-DscResourcePresent $value
    }

    It 'should pass along case sensitive and force args' {
        $value = Get-TargetResource -Path $script:iniPath -Name 'prefix' -CaseSensitive -Force
        $value.CaseSensitive | Should -BeTrue
        $value.Force | Should -BeTrue
    }

    It 'should get missing config value' {
        $value = Get-TargetResource -Path $script:iniPath -Name 'fubar'
        $value | Should -Not -BeNullOrEmpty
        $value.Value | Should -BeNullOrEmpty
        Assert-DscResourceAbsent $value
    }

    It 'should throw error if path does not exist' {
        $bogusPath = Join-Path -Path $script:tempDir -ChildPath 'bogus'
        $bogusPath | Should -Not -Exist
        $value = Get-TargetResource -Path $bogusPath -Name 'prefix' -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
        $value | Should -BeNullOrEmpty
    }

    It 'should be absent if path does not exist and force' {
        $bogusPath = Join-Path -Path $script:tempDir -ChildPath 'bogus'
        $bogusPath | Should -Not -Exist
        $value = Get-TargetResource -Path $bogusPath -Name 'prefix' -Force
        $Global:Error.Count | Should -Be 0
        $value | Should -Not -BeNullOrEmpty
        $value.Path | Should -Be $bogusPath
    }

    It 'should test config' {
        (Test-TargetResource -Path $script:iniPath -Name 'prefix' -Value (Get-TargetResource -Path $script:iniPath -Name 'prefix').Value) | Should -BeTrue
        (Test-TargetResource -Path $script:iniPath -Name 'prefix' -Value 'C:\I\Do\Not\Exist') | Should -BeFalse
    }

    It 'test missing config' {
        (Test-TargetResource -Path $script:iniPath -Name 'fubar' -Value 'fubar' -Ensure 'Absent') | Should -BeTrue
        (Test-TargetResource -Path $script:iniPath -Name 'fubar' -Value 'fubar') | Should -BeFalse
    }

    It 'should test missing ini path' {
        $bogusPath = Join-Path -Path $script:tempDir -ChildPath 'bogus'
        $bogusPath | Should -Not -Exist
        (Test-TargetResource -Path $bogusPath -Name 'prefix' -Value $script:defaultValue -ErrorAction SilentlyContinue) | Should -BeFalse
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not foun'
        $Error.Clear()
        (Test-TargetResource -Path $bogusPath -Name 'prefix' -Value $script:defaultValue -Force) | Should -BeFalse
        $Global:Error.Count | Should -Be 0
    }

    It 'should test value in section' {
        (Test-TargetResource -Path $script:iniPath -Section $script:sectionName -Name 'prefix' -Value $script:defaultValue2) | Should -BeTrue
        (Test-TargetResource -Path $script:iniPath -Section $script:sectionName -Name 'prefix' -Value $script:defaultValue) | Should -BeFalse
    }

    It 'should setup config' {
        $name = 'CarbonIniFile'
        $value = [Guid]::NewGuid().ToString()

        Set-TargetResource -Path $script:iniPath -Name $name -Value $value
        Assert-IniFile -Name $name -Value $value

        $newValue = [guid]::NewGuid().ToString()
        Set-TargetResource -Path $script:iniPath -Name $name -Value $newValue
        Assert-IniFile -Name $name -Value $newValue

        Set-TargetResource -Path $script:iniPath -Name $name -Ensure 'Absent'
        (Get-TargetResource -Path $script:iniPath -Name $name).Value | Should -BeNullOrEmpty
    }

    It 'should treat name as case sensitive' {
        $value1 = [Guid]::NewGuid()
        $value2 = [Guid]::NewGuid()

        Set-TargetResource -Path $script:iniPath -Name $script:testConfigName -Value $value1 -CaseSensitive
        Set-TargetResource -Path $script:iniPath -Name $script:testConfigName.ToUpper() -Value $value2 -CaseSensitive

        Assert-IniFile -Name $script:testConfigName -Value $value1 -CaseSensitive
        Assert-IniFile -Name $script:testConfigName.ToUpper() -Value $value2 -CaseSensitive
    }

    It 'should treat value as case sensitive' {
        $value1 = 'fubar'

        Set-TargetResource -Path $script:iniPath -Name $script:testConfigName -Value $value1
        (Test-TargetResource -Path $script:iniPath -Name $script:testConfigName -Value $value1 -CaseSensitive) | Should -BeTrue
        (Test-TargetResource -Path $script:iniPath -Name $script:testConfigName -Value $value1.ToUpper()) | Should -BeTrue
        (Test-TargetResource -Path $script:iniPath -Name $script:testConfigName -Value $value1.ToUpper() -CaseSensitive) | Should -BeFalse
    }

    It 'should not create missing ini file' {
        $bogusPath = Join-Path -Path $script:tempDir -ChildPath 'bogus'
        $bogusPath | Should -Not -Exist
        Set-TargetResource -Path $bogusPath -Name 'prefix' -Value $script:defaultValue2 -ErrorAction SilentlyContinue
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
        $bogusPath | Should -Not -Exist
    }

    It 'should create missing ini file' {
        $bogusPath = Join-Path -Path $script:tempDir -ChildPath 'bogusParent\bogusFile'
        $bogusPath | Should -Not -Exist
        Set-TargetResource -Path $bogusPath -Name 'prefix' -Value $script:defaultValue2 -Force
        $Global:Error.Count | Should -Be 0
        $bogusPath | Should -Exist
        $ini = Split-CIni -Path $bogusPath -AsHashtable
        $ini.ContainsKey('prefix') | Should -BeTrue
        $ini['prefix'].Value | Should -Be $script:defaultValue2
    }

    It 'should set value in section' {
        $newValue = [Guid]::NewGuid().ToString()
        Set-TargetResource -Path $script:iniPath -Section $script:sectionName -Name 'prefix' -Value $newValue
        Assert-IniFile -Section $script:sectionName -Name 'prefix' -Value $newValue
    }

    It 'should remove value in section' {
        Set-TargetResource -Path $script:iniPath -Section $script:sectionName -Name 'prefix' -Ensure Absent
        $ini = Split-CIni -Path $script:iniPath -AsHashtable
        $ini.ContainsKey( ('{0}.prefix' -f $script:sectionName) ) | Should -BeFalse
        $ini.ContainsKey('prefix') | Should -BeTrue
    }

    $skipDscTest =
        (Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True' -and $PSVersionTable['PSVersion'].Major -eq 7

    It 'should run through dsc' -Skip:$skipDscTest {
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
                    Path = $script:iniPath;
                    Name = $script:testConfigName
                    Value = $Value;
                    Ensure = $Ensure;
                }
            }
        }

        $value = [Guid]::NewGuid().ToString()

        & DscConfiguration -Value $value -OutputPath $CarbonDscOutputRoot

        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot  -Force
        $Global:Error.Count | Should -Be 0
        Assert-IniFile $value

        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot  -Force
        $Global:Error.Count | Should -Be 0
        Assert-IniFile $null

        $result = Get-DscConfiguration
        $Global:Error.Count | Should -Be 0
        $result | Should -BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_IniFile' } | Should -Not -BeNullOrEmpty
    }
}
