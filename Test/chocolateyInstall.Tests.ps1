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
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
$destinationDir = Join-Path -Path (Get-PowerShellModuleInstallPath) -ChildPath 'Carbon'
$installCarbonJunction = $false
$installCarbonJunction = (Test-PathIsJunction -Path $destinationDir)

function Init
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

Describe 'chocolateyInstall' {
    BeforeEach {
        Init
    }

    AfterEach {
        Init
    }
    
    It 'should copy into module install directory' {
        $destinationDir | Should -Not -Exist 
        & $chocolateyInstall
        $destinationDir | Should -Exist
        $sourceCount = (Get-ChildItem $destinationDir -Recurse | Measure-Object).Count
        $destinationCount = (Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon') -Recurse | Measure-Object).Count
        $destinationCount | Should -Be $sourceCount
    }
    
    It 'should remove what is there' {
        New-Item -Path $destinationDir -ItemType 'Directory'
        $deletedRecurseFilePath = Join-Path -Path $destinationDir -ChildPath 'should\deleteme.txt'
        $deletedRootFilePath = Join-Path -Path $destinationDir -ChildPath 'deleteme.txt'
        New-Item -Path $deletedRecurseFilePath -ItemType 'File' -Force
        New-Item -Path $deletedRootFilePath -ItemType 'File' -Force
    
        $deletedRootFilePath | Should -Exist
        $deletedRecurseFilePath | Should -Exist
    
        & $chocolateyInstall
    
        $deletedRootFilePath | Should -Not -Exist
        $deletedRecurseFilePath | Should -Not -Exist
    }
    
    It 'should handle module in use' {
        & $chocolateyInstall
    
        $markerFile = Join-Path -Path $destinationDir -ChildPath 'shouldnotgetdeleted'
        New-Item -Path $markerFile -ItemType 'file'
        $markerFile | Should -Exist
    
        $carbonFullClrDllPath = Join-Path -Path $destinationDir -ChildPath 'bin\fullclr\Carbon.dll' -Resolve
        $carbonCoreClrDllPath = Join-Path -Path $destinationDir -ChildPath 'bin\coreclr\Carbon.dll' -Resolve
    
        $preCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
    
        $fullClrFile = [IO.File]::Open($carbonFullClrDllPath, 'Open', 'Read', 'Read')
        $coreClrFile = [IO.File]::Open($carbonCoreClrDllPath, 'Open', 'Read', 'Read')
        try
        {
            & $chocolateyInstall
        }
        catch
        {
        }
        finally
        {
            $fullClrFile.Close()
            $coreClrFile.Close()
        }
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'Access to the path .* denied'
        $markerFile | Should -Exist
    
        $postCount = Get-ChildItem -Path $destinationDir -Recurse | Measure-Object | Select-Object -ExpandProperty 'Count'
        $postCount | Should -Be $preCount
    }
    
}

Init
if( $installCarbonJunction )
{
    Install-Junction -Link $destinationDir -Target (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon' -Resolve)
}
