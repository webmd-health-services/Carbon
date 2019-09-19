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

    It 'should find a group member' {
        $result = Test-GroupMember -GroupName $groupName -Member $userName
        $result | Should Be $true
        $Global:Error.Count | Should Be 0
    }

    It 'should not find a group member' {
        $user = Get-User | Select-Object -First 1
        $User | Should Not BeNullOrEmpty
        Test-GroupMember -GroupName $groupName -Member $user | Should Be $false
        $Global:Error.Count | Should Be 0
    }

    It 'should not find a non existent user' {
        $result = Test-GroupMember -GroupName $groupName -Member 'nonExistantUser' -ErrorAction SilentlyContinue
        $result | Should BeNullOrEmpty
        $Global:Error[0] | Should Match 'identity.*not found'
    }

    It 'should write an error if group does not exist' {
        $result = Test-GroupMember -GroupName 'oiuewldsanfds' -Member 'snafufubar' -ErrorAction SilentlyContinue
        $result | Should BeNullOrEmpty
        $Global:Error[0] | Should Match 'group.*not found'
    }
}