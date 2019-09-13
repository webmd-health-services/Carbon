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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-ServiceConfiguration' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should load all service configuration' {
        Get-Service | 
            Get-ServiceConfiguration | 
            Format-List -Property *
        $Global:Error.Count | Should -Be 0
    }
    
    It 'should load extended type data' {
        Get-Service | ForEach-Object {
            $service = $_
            $info = Get-ServiceConfiguration -Name $service.Name
            $info | 
                Get-Member -MemberType Property | 
                ForEach-Object { $info.($_.Name) | Should -Be $service.($_.Name) }
        }
        $Global:Error.Count | Should -Be 0
    }
}
