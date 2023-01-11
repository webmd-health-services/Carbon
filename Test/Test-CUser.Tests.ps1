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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
}

Describe 'Test-Cuser' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should check if local account exists' {
        $localUserAccounts = Get-CUser
        $localUserAccounts | Should -Not -BeNullOrEmpty
        foreach( $localUserAccount in $localUserAccounts )
        {
            Test-Cuser -Username $localUserAccount.Name | Should -BeTrue
        }
    }

    It 'should not find non existent account' {
        Test-Cuser -Username ([Guid]::NewGuid().ToString().Substring(0,20)) | Should -BeFalse
        $Global:Error | Should -BeNullOrEmpty
    }

}
