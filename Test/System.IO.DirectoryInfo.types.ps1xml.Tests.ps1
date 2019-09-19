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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

function GivenANormalDirectory
{
    $path = Join-Path -Path $TestDrive.FullName -ChildPath 'dir'
    New-Item -Path $path -ItemType 'Directory'
}

Describe 'Carbon.when getting normal directoryes' {
    $Global:Error.Clear()

    $dir = GivenANormalDirectory

    It 'should not be a junction' {
        $dir.IsJunction | Should Be $false
    }

    It 'should not be a symbolic link' {
        $dir.IsSymbolicLink | Should Be $false
    }

    It 'should not have a target path' {
        $dir.TargetPath | Should Be $null
    }

    It 'should write no errors' {
        $Global:Error | Should BeNullOrEmpty
    }
}

Describe 'Carbon.when getting symoblic link directories' {
    $Global:Error.Clear()
    $sourceDir = GivenANormalDirectory
    $symDirPath = Join-Path -Path $TestDrive.FullName -ChildPath 'destination'
    [Carbon.IO.SymbolicLink]::Create($symDirPath, $sourceDir.FullName, $true)

    try 
    {
            
        $dirInfo = Get-Item -Path $symDirPath

        It 'should be a junction' {
            $dirInfo.IsJunction | Should Be $true
        }

        It 'should be a symbolic link' {
            $dirInfo.IsSymbolicLink | Should Be $true
        }

        It 'should have a target path' {
            $dirInfo.TargetPath | Should Be $sourceDir.FullName
        }

        It 'should write no errors' {
            $Global:Error | Should BeNullOrEmpty
        }
    }
    finally
    {
        cmd /C rmdir $symDirPath
    }
}