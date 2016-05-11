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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

Describe 'CarbonVersion' {
    $expectedVersion = $null
    
    BeforeEach {
        $line = Get-Content -Path (Join-Path $PSScriptRoot '..\RELEASE NOTES.txt' -Resolve) | 
                    Where-Object { $_ -match '^# (\d+)\.(\d+)\.(\d+)\s*' } |
                    Select-Object -First 1
        
        $expectedVersion = New-Object Version $matches[1],$matches[2],$matches[3]
    }
    
    It 'carbon module version is correct' {
        $moduleInfo = Get-Module -Name Carbon
        $moduleInfo | Should Not BeNullOrEmpty
        $moduleInfo.Version.Major | Should Be $expectedVersion.Major
        $moduleInfo.Version.Minor | Should Be $expectedVersion.Minor
        $moduleInfo.Version.Build | Should Be $expectedVersion.Build
    }
    
    It 'carbon assembly version is correct' {
        Get-ChildItem (Join-Path $PSScriptRoot '..\Carbon\bin') Carbon*.dll | ForEach-Object {
    
            $_.VersionInfo.FileVersion | Should Be $expectedVersion
            $_.VersionInfo.ProductVersion.ToString().StartsWith($expectedVersion.ToString()) | Should Be $true
    
        }
    }
    
}
