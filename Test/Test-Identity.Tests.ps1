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

$user1 = $null
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
$user1 = Install-User -Credential (New-Credential -UserName 'CarbonTestUser1' -Password 'P@ssw0rd!') -PassThru

Describe 'Test-Identity' {
    It 'should find local group' {
        (Test-Identity -Name 'Administrators') | Should Be $true
    }
    
    It 'should find local user' {
        (Test-Identity -Name $user1.SamAccountName) | Should Be $true
    }
    
    if( (Get-WmiObject -Class 'Win32_ComputerSystem').Domain -ne 'WORKGROUP' )
    {
        It 'should find domain user' {
            (Test-Identity -Name ('{0}\Administrator' -f $env:USERDOMAIN)) | Should Be $true
        }
    }
    
    It 'should return security identifier' {
        $sid = Test-Identity -Name $user1.SamAccountName -PassThru
        $sid | Should Not BeNullOrEmpty
        ($sid -is [Carbon.Identity]) | Should Be $true
    }
    
    It 'should not find missing local user' {
        $error.Clear()
        (Test-Identity -Name 'IDoNotExistIHope') | Should Be $false
        $error.Count | Should Be 0
    }
    
    It 'should not find missing local user with computer for domain' {
        $error.Clear()
        (Test-Identity -Name ('{0}\IDoNotExistIHope' -f $env:COMPUTERNAME)) | Should Be $false
        $error.Count | Should Be 0
    }
    
    It 'should not find user in bad domain' {
        $error.Clear()
        (Test-Identity -Name 'MISSINGDOMAIN\IDoNotExistIHope' -ErrorAction SilentlyContinue) | Should Be $false
        $error.Count | Should Be 0
    }
    
    It 'should not find user in current domain' {
        $error.Clear()
        (Test-Identity -Name ('{0}\IDoNotExistIHope' -f $env:USERDOMAIN) -ErrorAction SilentlyContinue) | Should Be $false
        $error.Count | Should Be 0
    }
    
    It 'should find user with dot domain' {
        $users = Get-User
        $users | Should Not BeNullOrEmpty
        try
        {
            $foundAUser = $false
            foreach( $user in $users )
            {
                (Test-Identity -Name ('.\{0}' -f $user.SamAccountName)) | Should Be $true
                $foundAUser = $true
            }
            $foundAUser | Should Be $true
        }
        finally
        {
            $users | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should find local system' {
        (Test-Identity -Name 'LocalSystem') | Should Be $true
    }
}
