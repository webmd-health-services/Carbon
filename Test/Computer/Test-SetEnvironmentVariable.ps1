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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function TearDown
{
    @( 'Computer', 'User', 'Process' ) | 
        ForEach-Object { 
            $removeArgs = @{ "For$_" = $true; }
            Remove-EnvironmentVariable -Name $EnvVarName @removeArgs
        }
}

function Set-TestEnvironmentVariable($Scope)
{
    $value = [Guid]::NewGuid().ToString()
    $setArgs = @{ "For$Scope" = $true }
    Set-EnvironmentVariable -Name $EnvVarName -Value $value @setArgs
    Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
    return $value
}

function Test-ShouldSetEnvironmentVariableAtComputerScope
{
    Set-TestEnvironmentVariable -Scope Computer
}

function Test-ShouldSetEnvironmentVariableAtUserScope
{
    Set-TestEnvironmentVariable -Scope User
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
}

function Test-ShouldSetEnvironmentVariableAtProcessScope
{
    Set-TestEnvironmentVariable -Scope Process
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User'
}

function Test-ShouldNotSetVariableIfWhatIf
{
    Set-EnvironmentVariable -Name $EnvVarName -Value 'Doesn''t matter.' -ForProcess -WhatIf
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Process'
}

function Assert-TestEnvironmentVariableIs($ExpectedValue, $Scope)
{
    if( $Scope -eq 'Computer' )
    {
        $Scope = 'Machine'
    }
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope)
    Assert-Equal $ExpectedValue $actualValue "Environment variable not set at $Scope scope."
    
}
