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

Describe 'Test-Group' {
    It 'should check if local group exists' {
        $groups = Get-Group
        try
        {
            $groups | Should -Not -BeNullOrEmpty
            $groups |
                # Sometimes on the build server, groups come back without a name.
                Where-Object { $_.Name } | 
                ForEach-Object { Test-Group -Name $_.Name } |
                Should -BeTrue
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should not find non existent account' {
        $error.Clear()
        (Test-Group -Name ([Guid]::NewGuid().ToString().Substring(0,20))) | Should -BeFalse
        $error | Should -BeNullOrEmpty
    }
    
}
