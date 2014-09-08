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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force

$testConfigName = 'CarbonIniFileOption'
$tempDir = $null
$iniPath = $null
$defaultValue = $null

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'IniFile'
}

function Start-Test
{
    $tempDir = New-TempDir -Prefix $PSCommandPath
    $iniPath = Join-Path -Path $tempDir -ChildPath 'ini'
    $defaultValue = [Guid]::NewGuid().ToString()
    $null = New-Item -Path $iniPath -ItemType 'File'
    @'
prefix = {0}
'@ -f $defaultValue | Set-Content -Path $iniPath
}

function Stop-Test
{
    Remove-Item -Path $tempDir -Recurse
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldGetConfigValue
{
    $value = Get-TargetResource -Path $iniPath -Name 'prefix'
    Assert-NotNull $value
    Assert-Equal $value.Name 'prefix'
    Assert-IniFile -Name 'prefix' -Value $value.Value 
    Assert-DscResourcePresent $value
}

function Test-ShouldGetMissingConfigValue
{
    $value = Get-TargetResource -Path $iniPath -Name 'fubar'
    Assert-NotNull $value
    Assert-Null $value.Value
    Assert-DscResourceAbsent $value
}

function Test-ShouldTestConfig
{
    Assert-True (Test-TargetResource -Path $iniPath -Name 'prefix' -Value (Get-TargetResource -Path $iniPath -Name 'prefix').Value)
    Assert-False (Test-TargetResource -Path $iniPath -Name 'prefix' -Value 'C:\I\Do\Not\Exist')
}

function Test-TestMissingConfig
{
    Assert-True (Test-TargetResource -Path $iniPath -Name 'fubar' -Value 'fubar' -Ensure 'Absent')
    Assert-False (Test-TargetResource -Path $iniPath -Name 'fubar' -Value 'fubar')
}

function Test-ShouldSetupConfig
{
    $name = 'CarbonIniFile'
    $value = [Guid]::NewGuid().ToString()

    Set-TargetResource -Path $iniPath -Name $name -Value $value
    Assert-IniFile -Name $name -Value $value

    $newValue = [guid]::NewGuid().ToString()
    Set-TargetResource -Path $iniPath -Name $name -Value $newValue
    Assert-IniFile -Name $name -Value $newValue 

    Set-TargetResource -Path $iniPath -Name $name -Ensure 'Absent'
    Assert-Null (Get-TargetResource -Path $iniPath -Name $name).Value
}

function Test-ShouldTreatNameAsCaseSensitive
{
    $value1 = [Guid]::NewGuid()
    $value2 = [Guid]::NewGuid()

    Set-TargetResource -Path $iniPath -Name $testConfigName -Value $value1 -CaseSensitive
    Set-TargetResource -Path $iniPath -Name $testConfigName.ToUpper() -Value $value2 -CaseSensitive

    Assert-IniFile -Name $testConfigName -Value $value1 -CaseSensitive
    Assert-IniFile -Name $testConfigName.ToUpper() -Value $value2 -CaseSensitive
}

function Test-ShouldTreatValueAsCaseSensitive
{
    $value1 = 'fubar'

    Set-TargetResource -Path $iniPath -Name $testConfigName -Value $value1
    Assert-True (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1 -CaseSensitive)
    Assert-False (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1.ToUpper() -CaseSensitive)
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
function Test-ShouldRunThroughDsc
{
    $value = [Guid]::NewGuid().ToString()

    & DscConfiguration -Value $value -OutputPath $CarbonDscOutputRoot

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot 
    Assert-NoError
    Assert-IniFile $value 

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot 
    Assert-NoError
    Assert-IniFile $null
}

function Assert-IniFile
{
    param(
        [Parameter(Position=0)]
        $Value,
        $Name = $testConfigName,

        [Switch]
        $CaseSensitive = $false
    )

    Set-StrictMode -Version 'Latest'

    $ini = Split-Ini -Path $iniPath -AsHashtable -CaseSensitive:$CaseSensitive

    if( $Value -eq $null )
    {
        Assert-False ($ini.ContainsKey( $Name ))
    }
    else
    {
        Assert-True ($ini.ContainsKey( $Name ))
        Assert-Equal $Value $ini[$Name].Value -CaseSensitive:$CaseSensitive
    }
}