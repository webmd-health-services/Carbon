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
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetPowerShellPath
{
    $expectedPath = Join-Path $PSHome powershell.exe
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $expectedPath = $expectedPath -replace 'SysWOW64','System32'
    }
    Assert-Equal $expectedPath (Get-PowerShellPath)
}

function Test-ShouldGet32BitPowerShellPath
{
    $expectedPath = Join-Path $PSHome powershell.exe
    if( Test-OSIs64Bit )
    {
        $expectedPath = $expectedPath -replace 'System32','SysWOW64'
    }
    
    Assert-Equal $expectedPath (Get-PowerShellPath -x86)
}

function Test-ShouldGet64BitPowerShellUnder32BitPowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        $expectedPath = $PSHome -replace 'SysWOW64','System32'
        $expectedPath = Join-Path $expectedPath 'powershell.exe'
        Assert-Equal $expectedPath (Get-PowerShellPath)
    }
    else
    {
        Write-Warning 'This test is only valid if running 32-bit PowerShell on a 64-bit operating system.'
    }
}

function Test-ShouldGet32BitPowerShellUnder32BitPowerShell
{
    if( (Test-OsIs64Bit) -and (Test-PowerShellIs32Bit) )
    {
        Assert-Equal (Join-Path $PSHome 'powershell.exe') (Get-PowerShellPath -x86)
    }
    else
    {
        Write-Warning 'This test is only valid if running 32-bit PowerShell on a 64-bit operating system.'
    }
}

