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

if( $PSVersionTable.PSVersion -eq '3.0' )
{
    function Test-ShouldNotRunPowerShellUnderCLR2
    {
        $command = {
            $PSVersionTable.CLRVersion
        }
    
        $error.Clear()
        $result = Invoke-PowerShell -Command $command -Runtime v2.0 -ErrorAction SilentlyContinue
        Assert-Equal 1 $error.Count
        Assert-Null $result
        Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
    }
}
else
{
    function Test-ShouldRunPowerShellUnderCLR2
    {
        $command = {
            $PSVersionTable.CLRVersion
        }
    
        $result = Invoke-PowerShell -Command $command
        Assert-Equal 2 $result.Major
        Assert-Null ([Environment]::GetEnvironmentVariable('COMPLUS_ApplicationMigrationRuntimeActivationConfigPath'))
    }
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

function Test-ShouldNotRunx86PowerShellWithoutx86Flag
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $error.Clear()
        $result = Invoke-PowerShell -Command { $PSVersionTable } -ErrorAction SilentlyContinue
        Assert-Equal 1 $error.Count
        Assert-Null $result
    }
    else
    {
        Write-Warning "This test is only valid if running 32-bit PowerShell on a 64-bit operating system."
    }
}


function Test-ShouldRunx86PowerShellFromx86PowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $error.Clear()
        $result = Invoke-PowerShell -Command { $env:ProgramFiles } -x86
        Assert-Equal 0 $error.Count
        Assert-True ($result -like '*Program Files (x86)*')
    }
    else
    {
        Write-Warning "This test is only valid if running 32-bit PowerShell on a 64-bit operating system."
    }
}