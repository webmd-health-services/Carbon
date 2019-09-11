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

function GivenANormalFile
{
    $file = Join-Path -Path $TestDrive.FullName -ChildPath 'file'
    '' | Set-Content -Path $file
    Get-Item -Path $file
}

Describe 'Carbon.when getting normal files' {
    $file = GivenANormalFile

    It 'should not be a symbolic link' {
        $file.IsSymbolicLink | Should Be $false
    }
    It 'should not have a target path' {
        $file.TargetPath | Should Be $null
    }
}

Describe 'Carbon.when getting symoblic link files' {
    $file = GivenANormalFile
    $symFilePath = Join-Path -Path $TestDrive.FullName -ChildPath 'destination'
    $symFile = [Carbon.IO.SymbolicLink]::Create($symFilePath, $File.FullName, $false)

    $fileInfo = Get-Item -Path $symFilePath

    It 'should be a symbolic link' {
        $fileInfo.IsSymbolicLink | Should Be $true
    }
    It 'should have a target path' {
        $fileInfo.TargetPath | Should Be $file.FullName
    }
}