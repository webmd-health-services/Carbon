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

Describe 'Get-User' {
    It 'should get all users' {
        $users = Get-User
        try
        {
            $users | Should -Not -BeNullOrEmpty
            $users.Length | Should -BeGreaterThan 0
            
        }
        finally
        {
            $users | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should get one user' {
        Get-User |
            ForEach-Object { 
                $expectedUser = $_
                try
                {
                    $user = Get-User -Username $expectedUser.SamAccountName
                    try
                    {
                        $user | Should -HaveCount 1
                        $user.Sid | Should -Be $expectedUser.Sid
                    }
                    finally
                    {
                        if( $user )
                        {
                            $user.Dispose()
                        }
                    }
                }
                finally
                {
                    $expectedUser.Dispose()
                }
            }
    }
    
    It 'should error if user not found' {
        $Error.Clear()
        $user = Get-User -Username 'fjksdjfkldj' -ErrorAction SilentlyContinue
        $user | Should -BeNullOrEmpty
        $Error.Count | Should -Be 1
        $Error[0].Exception.Message | Should -BeLike '*not found*'
    }

    It 'should get users if WhatIfPreference is true' {
        $WhatIfPreference = $true
        $users = Get-CUser 
        $users | Should -Not -BeNullOrEmpty
        $users | 
            Select-Object -First 1 | 
            ForEach-Object { Get-CUser -UserName $_.SamAccountName } | 
            Should -Not -BeNullOrEmpty
    }
}
