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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-PathProvider' {
    
    It 'should get file system provider' {
        ((Get-PathProvider -Path 'C:\Windows').Name) | Should Be 'FileSystem'
    }
    
    It 'should get relative path provider' {
        ((Get-PathProvider -Path '..\').Name) | Should Be 'FileSystem'
    }
    
    It 'should get registry provider' {
        ((Get-PathProvider -Path 'hklm:\software').Name) | Should Be 'Registry'
    }
    
    It 'should get relative path provider' {
        Push-Location 'hklm:\SOFTWARE\Microsoft'
        try
        {
            ((Get-PathProvider -Path '..\').Name) | Should Be 'Registry'
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should get no provider for bad path' {
        ((Get-PathProvider -Path 'C:\I\Do\Not\Exist').Name) | Should Be 'FileSystem'
    }
    
}

Describe 'Get-PathProvider when passed a registry key PSPath' {
    It 'should return Registry' {
        Get-PathProvider -Path (Get-Item -Path 'hkcu:\software').PSPath | Select-Object -ExpandProperty 'Name' | Should Be 'Registry'
    }
}