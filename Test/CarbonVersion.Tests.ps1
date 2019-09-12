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

$manifest = Test-ModuleManifest -Path (Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\Carbon.psd1' -Resolve)
Describe 'CarbonVersion' {
    $expectedVersion = $null
    
    BeforeEach {
    }
    
    It 'carbon assembly version is correct' {
        $binPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Carbon\bin\*'
        Get-ChildItem -Path $binPath -Include 'Carbon*.dll' | ForEach-Object {
    
            $_.VersionInfo.FileVersion | Should Be $manifest.Version
            $_.VersionInfo.ProductVersion.ToString().StartsWith($manifest.Version.ToString()) | Should Be $true
        }
    }
}
