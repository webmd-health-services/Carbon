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

$GroupName = 'CarbonRemoveGroupMember'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)

function Get-Member
{
    Get-User | 
        Where-Object { $_.SamAccountName -ne $env:COMPUTERNAME }
}

Describe 'Remove-GroupMember' {
    BeforeEach {
        $Global:Error.Clear()
        $users = Get-Member
        try
        {
            Remove-Group
            Install-Group -Name $GroupName -Description "Group for testing the Remvoe-GroupMember Carbon function." -Member $users
            $group = Get-Group -Name $GroupName
            try
            {
                $group.Members.Count | Should Be $users.Count
            }
            finally
            {
                $group.Dispose()
            }
        }
        finally
        {
            $users | ForEach-Object { $_.Dispose() }
        }
    }
    
    AfterEach {
        Remove-Group
    }
    
    function Remove-Group
    {
        $group = Get-Group -Name $GroupName -ErrorAction Ignore
        try
        {
            if( $group -ne $null )
            {
                net localgroup `"$GroupName`" /delete
            }
        }
        finally
        {
            if( $group )
            {
                $group.Dispose()
            }
        }
    }
    
    It 'should remove individual members' {
        Get-Member | ForEach-Object { Remove-GroupMember -Name $GroupName -Member $_.SamAccountName ; $_.Dispose() }
        $Global:Error.Count | Should Be 0
        $group = Get-Group -Name $GroupName
        try
        {
            $group.Members.Count | Should Be 0
        }
        finally
        {
            $group.Dispose()
        }
    }
    
    It 'should remove bulk members' {
        $users = Get-Member
        try
        {
            Remove-GroupMember -Name $GroupName -Member $users
            $Global:Error.Count | Should Be 0
        }
        finally
        {
            $users | ForEach-Object { $_.Dispose() }
        }
    
        $group = Get-Group -Name $GroupName
        try
        {
            $group.Members.Count | Should Be 0
        }
        finally
        {
            $group.Dispose()
        }
    }
    
    It 'should support what if' {
        $users = Get-Member
        $users | ForEach-Object { Remove-GroupMember -Name $GroupName -Member $_.SamAccountName -WhatIf; $_.Dispose() }
        $group = Get-Group -Name $GroupName
        try
        {
            $group.Members.Count | Should Be $users.Count
        }
        finally
        {
            $group.Dispose()
        }
    }
}
