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
 
$EnvVarName = "CarbonRemoveEnvironmentVar"

function Assert-NoTestEnvironmentVariableAt( $Scope )
{
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope)
    It ('should remove variable from {0} scope' -f $Scope) {
        $actualValue | Should BeNullOrEmpty
    }
}

function Set-TestEnvironmentVariable($Scope)
{
    $EnvVarValue = [Guid]::NewGuid().ToString()
    [Environment]::SetEnvironmentVariable($EnvVarName, $EnvVarValue, $Scope)
        
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope) 
    It 'should set variable that will be deleted' {
        $actualValue | Should Be $EnvVarValue
    }
        
    return $EnvVarValue
}
   
Describe 'Remove-EnvironmentVariable when removing computer-level variable' {
    Set-TestEnvironmentVariable 'Machine'
    Remove-EnvironmentVariable -Name $EnvVarName -ForComputer
    Assert-NoTestEnvironmentVariableAt -Scope Machine
}
    
Describe 'Remove-EnvironmentVariable when remoing user-level variable' {
    Set-TestEnvironmentVariable 'User'
        
    Assert-NoTestEnvironmentVariableAt -Scope Machine
        
    Remove-EnvironmentVariable -Name $EnvVarName -ForUser
    
    Assert-NoTestEnvironmentVariableAt -Scope User
}
    
Describe 'Remove-EnvironmentVariable when removing process-level variable' {
    Set-TestEnvironmentVariable 'Process'
        
    Assert-NoTestEnvironmentVariableAt -Scope Machine
    Assert-NoTestEnvironmentVariableAt -Scope User
        
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess
    
    Assert-NoTestEnvironmentVariableAt -Scope Process
}
    
Describe 'Remove-EnvironmentVariable when variable doesn''t exist' {
    $Global:Error.Clear()
    Remove-EnvironmentVariable -Name "IDoNotExist" -ForComputer
    It 'should not write an error' {
        $Global:Error | Should BeNullOrEmpty
    }
}
    
Describe 'Remove-EnvironmentVariable when using -WhatIf switch' {
    $envVarValue = Set-TestEnvironmentVariable -Scope Process
        
    Remove-EnvironmentVariable -Name $EnvVarName -ForProcess -WhatIf
        
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, 'Process') 
    It 'should not remove variable' {
        $actualValue | Should Not BeNullOrEmpty
        $envVarValue | Should Be $actualValue
    }
}
    
@( 'Computer', 'User', 'Process') | 
    ForEach { 
        $removeArgs = @{ "For$_" = $true; }
        Remove-EnvironmentVariable -Name $EnvVarName @removeArgs
    }
