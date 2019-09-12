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

#Requires -Version 1
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Test-Service when testing an existing service' {
    $error.Clear()
    Get-Service | ForEach-Object {
        It ('should find the {0} {1} service' -f $_.ServiceName,$_.ServiceType) {
            Test-Service -Name $_.ServiceName | Should Be $true
            $Error.Count | Should Be 0
        }
    }
}

Describe 'Test-Service when testing for a non-existent service' {
    
    $error.Clear()

    It 'should not find missing service' {
        (Test-Service -Name 'ISureHopeIDoNotExist') | Should Be $false
        $error.Count | Should Be 0
    }
    
}

Describe 'Test-Service when testing for a device service' {
    $Error.Clear()
    [ServiceProcess.ServiceController]::GetDevices() | ForEach-Object {
        It ('should find the {0} {1} service' -f $_.ServiceName,$_.ServiceType) {
            Test-Service -Name $_.ServiceName | Should Be $true
            $Error.Count | Should Be 0
        }
    }
}