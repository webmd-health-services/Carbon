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

Describe 'Get-CPathProvider' {

    It 'should get file system provider' {
        ((Get-CPathProvider -Path 'C:\Windows' -NoWarn).Name) | Should Be 'FileSystem'
    }

    It 'should get relative path provider' {
        ((Get-CPathProvider -Path '..\' -NoWarn).Name) | Should Be 'FileSystem'
    }

    It 'should get registry provider' {
        ((Get-CPathProvider -Path 'hklm:\software' -NoWarn).Name) | Should Be 'Registry'
    }

    It 'should get relative path provider' {
        Push-Location 'hklm:\SOFTWARE\Microsoft'
        try
        {
            ((Get-CPathProvider -Path '..\' -NoWarn).Name) | Should Be 'Registry'
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should get no provider for bad path' {
        ((Get-CPathProvider -Path 'C:\I\Do\Not\Exist' -NoWarn).Name) | Should Be 'FileSystem'
    }

}

Describe 'Get-CPathProvider when passed a registry key PSPath' {
    It 'should return Registry' {
        Get-CPathProvider -Path (Get-Item -Path 'hkcu:\software').PSPath -NoWarn |
            Select-Object -ExpandProperty 'Name' |
            Should Be 'Registry'
    }
}