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
& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
$destinationDir = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath 'Carbon'
$installCarbonJunction = $false

function Start-TestFixture
{
    $installCarbonJunction = (Test-PathIsJunction -Path $destinationDir)
}

function Stop-TestFixture
{
    if( $installCarbonJunction )
    {
        Install-Junction -Link $destinationDir -Target (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve) -Verbose
    }
}

function Start-Test
{
    Stop-Test
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
}

function Test-ShouldCopyIntoModuleInstallDirectory
{
    Assert-DirectoryDoesNotExist $destinationDir
    & $chocolateyInstall
    Assert-DirectoryExists $destinationDir 
    $sourceCount = (Get-ChildItem $destinationDir -Recurse | Measure-Object).Count
    $destinationCount = (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon') -Recurse | Measure-Object).Count
    Assert-Equal  $sourceCount $destinationCount
}

function Test-ShouldRemoveWhatIsThere
{
    New-Item -Path $destinationDir -ItemType 'Directory'
    $deletedRecurseFilePath = Join-Path -Path $destinationDir -ChildPath 'should\deleteme.txt'
    $deletedRootFilePath = Join-Path -Path $destinationDir -ChildPath 'deleteme.txt'
    New-Item -Path $deletedRecurseFilePath -ItemType 'File' -Force
    New-Item -Path $deletedRootFilePath -ItemType 'File' -Force

    Assert-FileExists $deletedRootFilePath
    Assert-FileExists $deletedRecurseFilePath

    & $chocolateyInstall

    Assert-FileDoesNotExist $deletedRootFilePath
    Assert-FileDoesNotExist $deletedRecurseFilePath
}

function Test-ShouldHandleModuleInUse
{
    & $chocolateyInstall

    $markerFile = Join-Path -Path $destinationDir -ChildPath 'shouldnotgetdeleted'
    New-Item -Path $markerFile -ItemType 'file'
    Assert-FileExists $markerFile

    $carbonDllPath = Join-Path -Path $destinationDir -ChildPath 'bin\Carbon.dll' -Resolve

    $preCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'

    $file = [IO.File]::Open($carbonDllPath, 'Open', 'Read', 'Read')
    try
    {
        & $chocolateyInstall
    }
    catch
    {
    }
    finally
    {
        $file.Close()
    }
    Assert-Error -Last -Regex 'Access to the path .* denied'
    Assert-FileExists $markerFile

    $postCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    Assert-Equal $preCount $postCount 'some files were deleted during upgrade'
}

