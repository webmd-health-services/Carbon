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

$EnvVarName = "CarbonRemoveEnvironmentVar"

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function TearDown
{
    @( 'Computer', 'User', 'Process') | 
        ForEach { 
            $removeArgs = @{ "For$_" = $true; }
            Remove-EnvironmentVariable -Name $EnvVarName @removeArgs
        }
}

function Set-TestEnvironmentVariable($Scope)
{
    $EnvVarValue = [Guid]::NewGuid().ToString()
    [Environment]::SetEnvironmentVariable($EnvVarName, $EnvVarValue, $Scope)
    
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope) 
    Assert-Equal $EnvVarValue $actualValue "$Scope environment variable not set."
    
    return $EnvVarValue
}

function Test-ShouldRemoveMachineEnvironmentVar
{
    Set-TestEnvironmentVariable 'Machine'
    Remove-EnvironmentVariable -Name $EnvVarName -ForComputer
    Assert-NoTestEnvironmentVariableAt -Scope Machine
}

function Test-ShouldRemoveUserEnvironmentVar
{
    Set-TestEnvironmentVariable 'User'
    
    Assert-NoTestEnvironmentVariableAt -Scope Machine
    
    Remove-EnvironmentVariable -Name $EnvVarName -ForUser

    Assert-NoTestEnvironmentVariableAt -Scope User
}

function Test-ShouldRemoveProcessEnvironmentVar
{
    Set-TestEnvironmentVariable 'Process'
    
    Assert-NoTestEnvironmentVariableAt -Scope Machine
    Assert-NoTestEnvironmentVariableAt -Scope User
    
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess

    Assert-NoTestEnvironmentVariableAt -Scope Process
}

function Test-ShouldRemoveNonExistentEnvironmentVar
{
    Remove-EnvironmentVariable -Name "IDoNotExist" -ForComputer
}

function Test-ShouldSupportWhatIf
{
    $envVarValue = Set-TestEnvironmentVariable -Scope Process
    
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess -WhatIf
    
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, 'Process') 
    Assert-NotNull $actualValue "WhatIf parameter resulted in environment variable being deleted."
    Assert-Equal $actualValue $envVarValue "WhatIf parameter resulted in environment variable being deleted."
}

function Assert-NoTestEnvironmentVariableAt( $Scope )
{
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope)
    Assert-Null $actualValue "Environment variable '$EnvVarName' found at scope $Scope."
}

