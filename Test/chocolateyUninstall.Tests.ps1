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

$chocolateyInstall = Join-Path -Path $PSScriptRoot -ChildPath '..\tools\chocolateyInstall.ps1' -Resolve
$chocolateyUninstall = Join-Path -Path $PSScriptRoot -ChildPath '..\tools\chocolateyUninstall.ps1' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$destinationDir = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath 'Carbon'

function Start-TestFixture
{
    $installCarbonJunction = (Test-PathIsJunction -Path $destinationDir)
}

function Stop-TestFixture
{
    if( $installCarbonJunction )
    {
        Install-Junction -Link $destinationDir -Target (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve)
    }
}

function Start-Test
{
    Stop-Test
    & $chocolateyInstall
    Assert-NoError
    Assert-DirectoryExists $destinationDir
}

function Stop-Test
{
    if( (Test-PathIsJunction -Path $destinationDir) )
    {
        Uninstall-Junction -Path $destinationDir
    }
    elseif( (Test-Path -Path $destinationDir -PathType Container) )
    {
        Remove-Item -Path $destinationDir -Recurse -Force
    }

    Get-ChildItem -Path (Get-PowerShellModuleInstallPath) -Filter 'Carbon*.*' | Remove-Item -Recurse -Force
}

function Test-ShouldRemoveCarbonModule
{
    & $chocolateyUninstall -Verbose
    Assert-CarbonUninstalled
}

function Test-ShouldDeleteNothingIfModuleInUse
{
    $preCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'

    $carbonDllPath = Join-Path -Path $destinationDir -ChildPath 'bin\Carbon.dll' -Resolve
    $file = [IO.File]::Open($carbonDllPath, 'Open', 'Read', 'Read')
    try
    {
        & $chocolateyUninstall
    }
    catch
    {
    }
    finally
    {
        $file.Close()
    }
    Assert-Error
    Assert-DirectoryExists $destinationDir

    # Make sure no files were deleted during a failed uninstall
    $postCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    Assert-Equal $preCount $postCount 'some files were deleted during failed uninstall'
}

function Test-ShouldDeleteIfModuleNotInstalled
{
    & $chocolateyUninstall
    Assert-CarbonUninstalled

    & $chocolateyUninstall
    Assert-NoError
}

function Assert-CarbonUninstalled
{
    Assert-DirectoryDoesNotExist $destinationDir
    Assert-Null (Get-ChildItem -Path (Get-PowerShellModuleInstallPath) -Filter 'Carbon*')
}
