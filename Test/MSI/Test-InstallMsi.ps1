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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
$carbonNoOpMsiPath = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonNoOpMsi.msi' -Resolve

function Start-Test
{
    Uninstall-CarbonNoOpMsi
}

function Stop-Test
{
    Uninstall-CarbonNoOpMsi
}

function Test-ShouldValidateFileIsAnMSI
{
    Invoke-WindowsInstaller -Path $PSCommandPath -Quiet -ErrorAction SilentlyContinue
    Assert-Error -Count 2
}

function Test-ShouldSupportWhatIf
{
    Assert-CarbonNoOpNotInstalled
    $fakeInstallerPath = Join-Path $TestDir CarbonNoOpMsi.msi -Resolve
    Invoke-WindowsInstaller -Path $fakeInstallerPath -Quiet -WhatIf
    Assert-NoError
    Assert-LastProcessSucceeded
    Assert-CarbonNoOpNotInstalled
}

function Test-ShouldInstallMsi
{
    Assert-CarbonNoOpNotInstalled
    Install-Msi -Path $carbonNoOpMsiPath
    Assert-CarbonNoOpInstalled
}

function Test-ShouldHandleFailedInstaller
{
    Set-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -Value $true -ForComputer
    try
    {
        Install-Msi -Path (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonNoOpFailingMsi.msi' -Resolve) -ErrorAction SilentlyContinue
        Assert-CarbonNoOpNotInstalled
    }
    finally
    {
        Remove-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -ForComputer
    }
}

function Test-ShouldSupportWildcards
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    try
    {
        Copy-Item $carbonNoOpMsiPath -Destination (Join-Path -Path $tempDir -ChildPath 'One.msi')
        Copy-Item $carbonNoOpMsiPath -Destination (Join-Path -Path $tempDir -ChildPath 'Two.msi')
        Install-Msi -Path (Join-Path -Path $tempDir -ChildPath '*.msi') -Verbose
        Assert-CarbonNoOpInstalled
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Test-ShouldNotReinstallIfAlreadyInstalled
{
    # Remove the install directory, check that it didn't get re-created.
}

function Test-ShouldReinstallIfForcedTo
{
    # Remove the install directory, check that it got re-created.
}

function Assert-CarbonNoOpInstalled
{
    Assert-NoError
    $item = Get-ProgramInstallInfo -Name '*Carbon*'
    Assert-NotNull $item
}

function Assert-CarbonNoOpNotInstalled
{
    $item = Get-ProgramInstallInfo -Name '*Carbon*'
    Assert-Null $item
}

function Uninstall-CarbonNoOpMsi
{
    if( (Get-ProgramInstallInfo -Name 'Carbon NoOp') )
    {
        msiexec /uninstall $carbonNoOpMsiPath /quiet 
    }
}