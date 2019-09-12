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

Set-StrictMode -Version 'Latest'
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$EnvVarName = 'CarbonTestSetEnvironmentVariable'

function Assert-TestEnvironmentVariableIs($ExpectedValue, $Scope, $ExpectedName = $EnvVarName, [switch]$Force)
{
    if( $Scope -eq 'Computer' )
    {
        $Scope = 'Machine'
    }
    $actualValue = [Environment]::GetEnvironmentVariable($ExpectedName, $Scope)

    $qualifer = ''
    if( -not $ExpectedValue )
    {
        $qualifer = 'not '
    }

    It ('should {0}set the environment variable in {1} scope' -f $qualifer,$Scope) {
        $actualValue | Should Be $ExpectedValue
    }

    if( $Scope -eq 'Process' )
    {
        if( -not $Force )
        {
            $envPath = 'env:{0}' -f $EnvVarName
            It 'should not set the variable in the env: drive' {
                Test-Path -Path $envPath | Should Be $false
            }
        }
    }        
}

function Assert-TestEnvironmentVariableSetInEnvDrive
{
    param(
        $ExpectedName = $EnvVarName,
        $ExpectedValue
    )

    $envPath = 'env:{0}' -f $ExpectedName
    It 'should set the variable in the env: drive' {
        Test-Path -Path $envPath | Should Be $true
        (Get-Item -Path $envPath).Value | Should Be $ExpectedValue
    }
}
    
function Set-TestEnvironmentVariable($Scope, $Value)
{
    $setArgs = @{ "For$Scope" = $true }
    
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess -ForUser -ForComputer

    Set-EnvironmentVariable -Name $EnvVarName -Value $value @setArgs
    Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
    return $value
}

function New-TestValue
{
    [Guid]::NewGuid().ToString()
}
    
Describe 'Set-Environment Variable when setting machine-level variable' {
    $value = New-TestValue
    Set-TestEnvironmentVariable -Scope Computer -Value $value
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope User
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope Process
}
    
Describe 'Set-EnvironmentVariable when setting user-level variable for current user' {
    $value = New-TestValue
    Set-TestEnvironmentVariable -Scope User -Value $value
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope Process
}
    
Describe 'Set-EnvironmentVariable when setting process-level variable' {
    $name = 'Carbon+Set-EnvironmentVariable+ForProcess'
    $value = New-TestValue
    Remove-EnvironmentVariable -Name $name -ForProcess -ForUser -ForComputer

    Set-EnvironmentVariable -Name $name -Value $value -ForProcess
    try
    {
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer' -ExpectedName $name
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User' -ExpectedName $name
        Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope 'Process' -ExpectedName $name
        Assert-TestEnvironmentVariableSetInEnvDrive -ExpectedValue $value  -ExpectedName $name
    }
    finally
    {
        Remove-EnvironmentVariable -Name $name -ForProcess -ForUser -ForComputer
    }
}

foreach( $scope in 'Computer','User','Process' )
{
    Describe ('Set-Environment when forcing set at the {0} level' -f $scope) {
        $value = New-TestValue
        $scopeParam = @{ 
                            ('For{0}' -f $scope) = $true
                       }
        Set-EnvironmentVariable -Name $EnvVarName -Value $value -Force @scopeParam
        Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $scope -Force
        Assert-TestEnvironmentVariableSetInEnvDrive -ExpectedValue $value
    }
}

Describe 'Set-EnvironmentVariable when using -WhatIf switch' {
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess -ForUser -ForComputer
    Set-EnvironmentVariable -Name $EnvVarName -Value 'Doesn''t matter.' -ForProcess -WhatIf
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User'
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Process'
}

Describe 'Set-EnvironmentVariable when setting variable for another user' {
    $name = [Guid]::NewGuid().ToString()
    $expectedValue = New-TestValue
    Set-EnvironmentVariable -Name $name -Value $expectedValue -ForUser -Credential $CarbonTestUser 
    $job = Start-Job -ScriptBlock {
        Get-Item -Path ('env:{0}' -f $using:name) | Select-Object -ExpandProperty 'Value'
    } -Credential $CarbonTestUser
    $actualValue = $job | Wait-Job | Receive-Job
    $job | Remove-Job -Force -ErrorAction Ignore

    It 'should set that user''s environment variable' {
        $actualValue | Should -Be $expectedValue
    }
}

Remove-EnvironmentVariable -Name $EnvVarName -ForProcess -ForUser -ForComputer
