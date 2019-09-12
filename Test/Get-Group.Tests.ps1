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

Describe 'Get-Group' {
    It 'should get all groups' {
        $groups = Get-Group
        try
        {
            $groups | Should -Not -BeNullOrEmpty
            $groups.Length | Should -BeGreaterThan 0
            
        }
        finally
        {
            $groups | ForEach-Object { $_.Dispose() }
        }
    }
    
    It 'should get one group' {
        Get-Group |
            ForEach-Object { 
                $expectedGroup = $_
                try
                {
                    $group = Get-Group -Name $expectedGroup.Name
                    try
                    {
                        $group | Should -HaveCount 1
                        $group.Sid | Should -Be $expectedGroup.Sid
                    }
                    finally
                    {
                        if( $group )
                        {
                            $group.Dispose()
                        }
                    }
                }
                finally
                {
                    $expectedGroup.Dispose()
                }
            }
    }
    
    It 'should error if group not found' {
        $Error.Clear()
        $group = Get-Group -Name 'fjksdjfkldj' -ErrorAction SilentlyContinue
        $group | Should -BeNullOrEmpty
        $Error.Count | Should -Be 1
        $Error[0].Exception.Message | Should -BeLike '*not found*'
    }

    It 'should get groups if WhatIfPreference is true' {
        $WhatIfPreference = $true
        $groups = Get-CGroup 
        $groups | Should -Not -BeNullOrEmpty
        $groups | 
            Select-Object -First 1 | 
            ForEach-Object { Get-CGroup -Name $_.Name } | 
            Should -Not -BeNullOrEmpty
    }
}
