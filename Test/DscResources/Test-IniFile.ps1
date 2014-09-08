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
$npmrcPath = Join-Path -Path (Split-Path -Parent -Path (Get-Command -Name 'npm.cmd').Path) -ChildPath 'node_modules\npm\npmrc' -Resolve

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'IniFile'
}

function Start-Test
{
    Remove-NpmTestConfigOption
}

function Stop-Test
{
    Remove-NpmTestConfigOption
}

function Remove-NpmTestConfigOption
{
    Remove-IniEntry -Path $npmrcPath -Name $testConfigName

    $value = npm config get $testConfigName --global
    if( ($value -and $value -ne 'undefined') )
    {
        npm config delete $testConfigName --global 2> $null
        Assert-NoError
    }

    $value = npm config get $testConfigName
    if( ($value -and $value -ne 'undefined') )
    {
        npm config delete $testConfigName 2> $null
        Assert-NoError
    }
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldGetConfigValue
{
    $value = Get-TargetResource -Name 'prefix'
    Assert-NotNull $value
    Assert-Equal $value.Name 'prefix'
    Assert-IniFile -Name 'prefix' -Value $value.Value 
    Assert-DscResourcePresent $value
}

function Test-ShouldGetMissingConfigValue
{
    $value = Get-TargetResource -Name 'fubar'
    Assert-NotNull $value
    Assert-Null $value.Value
    Assert-DscResourceAbsent $value
}

function Test-ShouldTestConfig
{
    Assert-True (Test-TargetResource -Name 'prefix' -Value (Get-TargetResource -Name 'prefix').Value -Ensure 'Present')
    Assert-False (Test-TargetResource -Name 'prefix' -Value 'C:\I\Do\Not\Exist' -Ensure 'Present')
}

function Test-TestMissingConfig
{
    Assert-True (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Absent')
    Assert-False (Test-TargetResource -Name 'fubar' -Value 'fubar' -Ensure 'Present')
}

function Test-ShouldHandleConfigSetWithUndefinedAsValue
{
    Assert-Equal 'undefined' (npm config get $testConfigName --global)
    $resource = Get-TargetResource -Name $testConfigName
    Assert-NotNull $resource
    Assert-Null $resource.Value
    Assert-DscResourceAbsent $resource
}

function Test-ShouldSetupConfig
{
    $name = 'CarbonIniFile'
    $value = [Guid]::NewGuid().ToString()

    Set-TargetResource -Name $name -Value $value -Ensure 'Present'
    Assert-IniFile -Name $name -Value $value

    $newValue = [guid]::NewGuid().ToString()
    Set-TargetResource -Name $name -Value $newValue -Ensure 'Present'
    Assert-IniFile -Name $name -Value $newValue 

    Set-TargetResource -Name $name -Ensure 'Absent'
    Assert-Null (Get-TargetResource -Name $name).Value
}

function Test-ShouldTreatNameAsCaseSensitive
{
    $value1 = [Guid]::NewGuid()
    $value2 = [Guid]::NewGuid()

    Set-TargetResource -Name $testConfigName -Value $value1 -Ensure 'Present'
    Set-TargetResource -Name $testConfigName.ToUpper() -Value $value2 -Ensure 'Present'

    try
    {
        Assert-IniFile $value1
        Assert-IniFile -Name $testConfigName.ToUpper() -Value $value2
    }
    finally
    {
        Remove-IniEntry -Path $npmrcPath -Name $testConfigName.ToUpper() 
        #npm config delete $testConfigName.ToUpper() --global
    }
}

function Test-ShouldTreatValueAsCaseSensitive
{
    $value1 = 'fubar'

    Set-TargetResource -Name $testConfigName -Value $value1 -Ensure 'Present'
    Assert-True (Test-TargetResource -Name $testConfigName -Value $value1 -Ensure 'Present')
    Assert-False (Test-TargetResource -Name $testConfigName -Value $value1.ToUpper() -Ensure 'Present')    
}

configuration DscConfiguration
{
    param(
        $Value,
        $Ensure
    )

    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        Carbon_IniFile set
        {
            Name = $testConfigName
            Value = $Value;
            Ensure = $Ensure;
        }
    }
}
function Test-ShouldRunThroughDsc
{
    $value = [Guid]::NewGuid().ToString()

    & DscConfiguration -Value $value -Ensure 'Present' -OutputPath $CarbonDscOutputRoot

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
        $Name = $testConfigName
    )

    Set-StrictMode -Version 'Latest'

    while( $Value -match '\$\{(.+?)\}' )
    {
        $envVarName = $Matches[1]
        $replaceRegex = '${{{0}}}' -f $envVarName
        $replaceRegex = [Text.RegularExpressions.RegEx]::Escape($replaceRegex)
        $envVarValue = Get-Item -Path ('env:{0}' -f $envVarName) -ErrorAction Ignore | Select-Object -ExpandProperty 'Value'
        $Value = $Value -replace $replaceRegex,$envVarValue
    }

    $actualValue = npm config get $Name --global
    if( $Value -eq $null )
    {
        Assert-Equal 'undefined' $actualValue
    }
    else
    {
        Assert-Equal $Value $actualValue -CaseSensitive
    }
}