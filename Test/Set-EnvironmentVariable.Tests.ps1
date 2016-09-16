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
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

$EnvVarName = 'CarbonTestSetEnvironmentVariable'

function Assert-TestEnvironmentVariableIs($ExpectedValue, $Scope, $ExpectedName = $EnvVarName)
{
    if( $Scope -eq 'Computer' )
    {
        $Scope = 'Machine'
    }
    $actualValue = [Environment]::GetEnvironmentVariable($ExpectedName, $Scope)

    It ('should set the environment variable in {0} scope' -f $Scope) {
        $actualValue | Should Be $ExpectedValue
    }
}
    
function Set-TestEnvironmentVariable($Scope)
{
    $value = [Guid]::NewGuid().ToString()
    $setArgs = @{ "For$Scope" = $true }
    
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess
    Remove-EnvironmentVariable -Name $EnvVarName -ForUser
    Remove-EnvironmentVariable -Name $EnvVarName -ForComputer

    Set-EnvironmentVariable -Name $EnvVarName -Value $value @setArgs
    Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
    return $value
}
    
Describe 'Set-Environment Variable when setting machine-level variable' {
    Set-TestEnvironmentVariable -Scope Computer
}
    
Describe 'Set-EnvironmentVariable when setting user-level variable for current user' {
    Set-TestEnvironmentVariable -Scope User
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer'
}
    
Describe 'Set-EnvironmentVariable when setting process-level variable' {
    $name = 'Carbon+Set-EnvironmentVariable+ForProcess'
    Remove-EnvironmentVariable -Name $name -ForProcess
    Remove-EnvironmentVariable -Name $name -ForComputer
    Remove-EnvironmentVariable -Name $name -ForUser
    $value = ([Guid]::NewGuid())
    Set-EnvironmentVariable -Name $name -Value $value -ForProcess
    try
    {
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Computer' -ExpectedName $name
        Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User' -ExpectedName $name
        Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope 'Process' -ExpectedName $name
        It 'should set environment variable in current process' {
            (Get-Item -Path ('env:{0}' -f $name)).Value | Should Be $value
        }
    }
    finally
    {
        Remove-EnvironmentVariable -Name $name -ForProcess
        Remove-EnvironmentVariable -Name $name -ForComputer
        Remove-EnvironmentVariable -Name $name -ForUser
    }
}
    
Describe 'Set-EnvironmentVariable when using -WhatIf switch' {
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess
    Set-EnvironmentVariable -Name $EnvVarName -Value 'Doesn''t matter.' -ForProcess -WhatIf
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Process'
}

@( 'Computer', 'User', 'Process' ) | 
    ForEach-Object { 
        $removeArgs = @{ "For$_" = $true; }
        Remove-EnvironmentVariable -Name $EnvVarName @removeArgs
    }
