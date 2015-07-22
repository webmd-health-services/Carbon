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
$carbonTestInstaller = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstaller.msi' -Resolve
$carbonTestInstallerActions = Join-Path -Path $PSScriptRoot -ChildPath 'CarbonTestInstallerWithCustomActions.msi' -Resolve

function Start-Test
{
    Uninstall-CarbonTestInstaller
}

function Stop-Test
{
    Uninstall-CarbonTestInstaller
}

function Test-ShouldValidateFileIsAnMSI
{
    Invoke-WindowsInstaller -Path $PSCommandPath -ErrorAction SilentlyContinue
    Assert-Error -Count 2
}

function Test-ShouldSupportWhatIf
{
    Assert-CarbonTestInstallerNotInstalled
    Invoke-WindowsInstaller -Path $carbonTestInstaller -WhatIf
    Assert-NoError
    Assert-LastProcessSucceeded
    Assert-CarbonTestInstallerNotInstalled
}

function Test-ShouldInstallMsi
{
    Assert-CarbonTestInstallerNotInstalled
    Install-Msi -Path $carbonTestInstaller
    Assert-CarbonTestInstallerInstalled
}

function Test-ShouldWarnQuietSwitchIsObsolete
{
    $warnings = @()
    Install-Msi -Path $carbonTestInstaller -Quiet -WarningVariable 'warnings'
    Assert-Equal 1 $warnings.Count
    Assert-Like $warnings[0] '*obsolete*'
}

function Test-ShouldHandleFailedInstaller
{
    Set-EnvironmentVariable -Name 'CARBON_TEST_INSTALLER_THROW_INSTALL_EXCEPTION' -Value $true -ForComputer
    try
    {
        Install-Msi -Path $carbonTestInstallerActions -ErrorAction SilentlyContinue
        Assert-CarbonTestInstallerNotInstalled
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
        Copy-Item $carbonTestInstaller -Destination (Join-Path -Path $tempDir -ChildPath 'One.msi')
        Copy-Item $carbonTestInstaller -Destination (Join-Path -Path $tempDir -ChildPath 'Two.msi')
        Install-Msi -Path (Join-Path -Path $tempDir -ChildPath '*.msi')
        Assert-CarbonTestInstallerInstalled
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse
    }
}

function Test-ShouldNotReinstallIfAlreadyInstalled
{
    Install-Msi -Path $carbonTestInstallerActions
    Assert-CarbonTestInstallerInstalled
    $msi = Get-Msi -Path $carbonTestInstallerActions
    $installDir = Join-Path ${env:ProgramFiles(x86)} -ChildPath ('{0}\{1}' -f $msi.Manufacturer,$msi.ProductName)
    Assert-DirectoryExists $installDir
    Remove-Item -Path $installDir -Recurse
    Install-Msi -Path $carbonTestInstallerActions
    Assert-DirectoryDoesNotExist $installDir
}

function Test-ShouldReinstallIfForcedTo
{
    Install-Msi -Path $carbonTestInstallerActions
    Assert-CarbonTestInstallerInstalled
    $msi = Get-Msi -Path $carbonTestInstallerActions

    $installDir = Join-Path ${env:ProgramFiles(x86)} -ChildPath ('{0}\{1}' -f $msi.Manufacturer,$msi.ProductName)
    $maxTries = 100
    $tryNum = 0
    do
    {
        if( (Test-Path -Path $installDir -PathType Container) )
        {
            break
        }
        Start-Sleep -Milliseconds 100
    }
    while( $tryNum++ -lt $maxTries )

    Assert-DirectoryExists $installDir
    Remove-Item -Path $installDir -Recurse
    Install-Msi -Path $carbonTestInstallerActions -Force
    Assert-DirectoryExists $installDir
}

function Test-ShouldInstallMsiWithSpacesInPath
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    try
    {
        $newInstaller = Join-Path -Path $tempDir -ChildPath 'Installer With Spaces.msi'
        Copy-Item -Path $carbonTestInstaller -Destination $newInstaller
        Install-Msi -Path $newInstaller
        Assert-CarbonTestInstallerInstalled
    }
    finally
    {
        Remove-Item -Path $tempDir -Recurse
    }

}

function Assert-CarbonTestInstallerInstalled
{
    Assert-NoError
    $maxTries = 100
    $tryNum = 0
    do
    {
        $item = Get-ProgramInstallInfo -Name '*Carbon*'
        if( $item )
        {
            break
        }

        Start-Sleep -Milliseconds 100
    }
    while( $tryNum++ -lt $maxTries )
    Assert-NotNull $item
}

function Assert-CarbonTestInstallerNotInstalled
{
    $item = Get-ProgramInstallInfo -Name '*Carbon*'
    Assert-Null $item
}

function Uninstall-CarbonTestInstaller
{
    Get-ChildItem -Path $PSScriptRoot -Filter *.msi |
        Get-Msi |
        Where-Object { Get-ProgramInstallInfo -Name $_.ProductName } |
        ForEach-Object {
            msiexec /f $_.Path /quiet
            msiexec /uninstall $_.Path /quiet
        }
}