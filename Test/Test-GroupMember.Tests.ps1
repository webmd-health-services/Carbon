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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1')

# I know, these should be inside the describe block, but when inside the describe block
#     the variables are unable to be resolved
$groupName = 'TestGroupMember01'
$userName = 'TestGroupMemberUser'
$userPass = 'P@ssw0rd!'
$description = 'Used by Test-GroupMember.Tests.ps1'

describe Test-GroupMember {
    
    BeforeAll {

        Install-Group -Name $groupName -Description $description

        $testUserCred = New-Credential -UserName $userName -Password $userPass
        Install-User -Credential $testUserCred -Description $description

        Add-GroupMember -Name $groupName -Member $userName
    }

    AfterAll {
        Uninstall-User -Username $userName
        Uninstall-Group -Name $groupName
    }

    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should find the local user' {
        $result = Test-GroupMember -Name $groupName -Member $userName
        $result | Should Be $true
        $Global:Error.Count | Should Be 0
    }

    It 'should not find the local user' {
        $result = Test-GroupMember -Name $groupName -Member 'nonExistantUser'
        $result | Should Be $false
        $Global:Error.Count | Should Be 1
    }
}