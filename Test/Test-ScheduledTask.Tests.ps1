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

function Init
{
    $Global:Error.Clear()
}

Describe 'Test-ScheduledTask' {
    BeforeEach {
        Init
    }

    It 'should find existing task' {
        $task = Get-ScheduledTask | Select-Object -First 1
        $task | Should -Not -BeNullOrEmpty
        (Test-ScheduledTask -Name $task.FullName) | Should -BeTrue
        $Global:Error.Count | Should -Be 0
    }
    
    It 'should not find non existent task' {
        (Test-ScheduledTask -Name 'fubar') | Should -BeFalse
        $Global:Error.Count | Should -Be 0
    }
}
