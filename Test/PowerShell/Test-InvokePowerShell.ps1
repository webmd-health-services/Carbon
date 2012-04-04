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

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldInvokePowerShell
{
    $command = {
        param(
            $Argument
        )
        
        $Argument
    }
    
    $result = Invoke-PowerShell -Command $command -Args 'Hello World!'
    Assert-Equal 'Hello world!' $result
}

function Test-ShouldInvokePowerShellx86
{
    $command = {
        $env:PROCESSOR_ARCHITECTURE
    }
    
    $result = Invoke-PowerShell -Command $command -x86
    Assert-Equal 'x86' $result
}

function Test-ShouldRunPowerShellUnderCLR2
{
    $command = {
        $PSVersionTable.CLRVersion
    }
    
    $result = Invoke-PowerShell -Command $command
    Assert-Equal 2 $result.Major
}

function Test-ShouldRunPowerShellUnderCLR4
{
    $command = {
        $PSVersionTable.CLRVersion
    }
    
    $result = Invoke-PowerShell -Command $command -Runtime v4.0
    Assert-Equal 4 $result.Major
    Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
}
