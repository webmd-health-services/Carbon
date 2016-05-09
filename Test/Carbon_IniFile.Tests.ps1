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
$sectionName = $null
$defaultValue = $null
$defaultValue2 = $null

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'IniFile'
}

function Start-Test
{
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
    Assert-Equal $iniPath $value.Path
    Assert-Equal $value.Name 'prefix'
    Assert-Equal $defaultValue $value.Value
    Assert-False $value.CaseSensitive
    Assert-False $value.Force
    Assert-IniFile -Name 'prefix' -Value $value.Value
    Assert-DscResourcePresent $value
}

function Test-ShouldGetSectionConfigValue
{
    $value = Get-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix'
    Assert-NotNull $value
    Assert-Equal $sectionName $value.Section 
    Assert-Equal 'prefix' $value.Name 
    Assert-Equal $defaultValue2 $value.Value
    Assert-IniFile -Section $sectionName -Name 'prefix' -Value $value.Value
    Assert-DscResourcePresent $value
}

function Test-ShouldPassAlongCaseSensitiveAndForceArgs
{
    $value = Get-TargetResource -Path $iniPath -Name 'prefix' -CaseSensitive -Force
    Assert-True $value.CaseSensitive
    Assert-True $value.Force
}

function Test-ShouldGetMissingConfigValue
{
    $value = Get-TargetResource -Path $iniPath -Name 'fubar'
    Assert-NotNull $value
    Assert-Null $value.Value
    Assert-DscResourceAbsent $value
}

function Test-ShouldThrowErrorIfPathDoesNotExist
{
    $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
    Assert-FileDoesNotExist $bogusPath
    $value = Get-TargetResource -Path $bogusPath -Name 'prefix' -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-Null $value
}

function Test-ShouldBeAbsentIfPathDoesNotExistAndForce
{
    $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
    Assert-FileDoesNotExist $bogusPath
    $value = Get-TargetResource -Path $bogusPath -Name 'prefix' -Force
    Assert-NoError
    Assert-NotNull $value
    Assert-Equal $bogusPath $value.Path
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

function Test-ShouldTestMissingIniPath
{
    $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
    Assert-FileDoesNotExist $bogusPath
    Assert-False (Test-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue -ErrorAction SilentlyContinue)
    Assert-Error -Last -Regex 'not foun'
    $Error.Clear()
    Assert-False (Test-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue -Force)
    Assert-NoError
}

function Test-ShouldTestValueInSection
{
    Assert-True (Test-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Value $defaultValue2)
    Assert-False (Test-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Value $defaultValue)
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
    Assert-True (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1.ToUpper())
    Assert-False (Test-TargetResource -Path $iniPath -Name $testConfigName -Value $value1.ToUpper() -CaseSensitive)
}

function Test-ShouldNotCreateMissingIniFile
{
    $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogus'
    Assert-FileDoesNotExist $bogusPath
    Set-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue2 -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex 'not found'
    Assert-FileDoesNotExist $bogusPath
}

function Test-ShouldCreateMissingIniFile
{
    $bogusPath = Join-Path -Path $tempDir -ChildPath 'bogusParent\bogusFile'
    Assert-FileDoesNotExist $bogusPath
    Set-TargetResource -Path $bogusPath -Name 'prefix' -Value $defaultValue2 -Force
    Assert-NoError
    Assert-FileExists $bogusPath
    $ini = Split-Ini -Path $bogusPath -AsHashtable
    Assert-True $ini.ContainsKey('prefix')
    Assert-Equal $defaultValue2 $ini['prefix'].Value
}

function Test-ShouldSetValueInSection
{
    $newValue = [Guid]::NewGuid().ToString()
    Set-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Value $newValue
    Assert-IniFile -Section $sectionName -Name 'prefix' -Value $newValue
}

function Test-ShouldRemoveValueInSection
{
    Set-TargetResource -Path $iniPath -Section $sectionName -Name 'prefix' -Ensure Absent
    $ini = Split-Ini -Path $iniPath -AsHashtable
    Assert-False $ini.ContainsKey( ('{0}.prefix' -f $sectionName) )
    Assert-True $ini.ContainsKey('prefix')
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

    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot  -Force
    Assert-NoError
    Assert-IniFile $value 

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot  -Force
    Assert-NoError
    Assert-IniFile $null
}

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
        Assert-False ($ini.ContainsKey( $key ))
    }
    else
    {
        Assert-True ($ini.ContainsKey( $key ))
        Assert-Equal $Value $ini[$key].Value -CaseSensitive:$CaseSensitive
    }
}
