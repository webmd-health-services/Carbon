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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldValidateFileIsAnMSI
{
    $error.Clear()
    Invoke-WindowsInstaller -Path (Join-Path $TestDir Test-InvokeWindowsInstaller.ps1 -Resolve) -Quiet -ErrorAction SilentlyContinue
    Assert-Equal 1 $error.Count
}

function Test-ShouldSupportWhatIf
{
    $fakeInstallerPath = Join-Path $TestDir FakeInstaller.msi -Resolve
    $error.Clear()
    Invoke-WindowsInstaller -Path $fakeInstallerPath -Quiet -WhatIf
    Assert-Equal 0 $error.Count
    Assert-Equal 0 $LastExitCode
}
