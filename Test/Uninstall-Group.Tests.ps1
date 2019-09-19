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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1')

describe Uninstall-Group {

    $groupName = 'TestUninstallGroup'
    $description = 'Used by Uninstall-Group.Tests.ps1'

    BeforeEach {
        Install-Group -Name $groupName -Description $description
        $Global:Error.Clear()
    }

    AfterEach {
        Uninstall-Group -Name $groupName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should remove the group' {
        Test-Group -Name $groupName | Should Be $true
        Uninstall-Group -Name $groupName
        Test-Group -Name $groupName | Should Be $false
    }

    It 'should remove nonexistent group without errors' {
        Uninstall-Group -Name 'fubarsnafu'
        $Global:Error.Count | Should Be 0
    }

    It 'should support WhatIf' {
        Uninstall-Group -Name $groupName -WhatIf
        Test-Group -Name $groupName | Should Be $true
    }
}
