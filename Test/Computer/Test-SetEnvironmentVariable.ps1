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

$EnvVarName = 'CarbonTestSetEnvironmentVariable'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon)
}

function TearDown
{
    @( 'Machine', 'User', 'Process' ) | % { Remove-EnvironmentVariable -Name $EnvVarName -Scope $_ }
    Remove-Module Carbon
}

function Set-TestEnvironmentVariable($Scope)
{
    $value = [Guid]::NewGuid().ToString()
    Set-EnvironmentVariable -Name $EnvVarName -Value $value -Scope $Scope
    Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
    return $value
}

function Test-ShouldSetEnvironmentVariableAtMachineScope
{
    Set-TestEnvironmentVariable -Scope Machine
}

function Test-ShouldSetEnvironmentVariableAtUserScope
{
    Set-TestEnvironmentVariable -Scope User
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Machine'
}

function Test-ShouldSetEnvironmentVariableAtProcessScope
{
    Set-TestEnvironmentVariable -Scope Process
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Machine'
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User'
}

function Test-ShouldNotSetVariableIfWhatIf
{
    Set-EnvironmentVariable -Name $EnvVarName -Value 'Doesn''t matter.' -Scope 'Process' -WhatIf
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Process'
}

function Assert-TestEnvironmentVariableIs($ExpectedValue, $Scope)
{
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope)
    Assert-Equal $ExpectedValue $actualValue "Environment variable not set at $Scope scope."
    
}
