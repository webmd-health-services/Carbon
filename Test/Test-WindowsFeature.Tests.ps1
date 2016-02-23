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

Write-Verbose -Message ('=' * 70) -Verbose
Write-Verbose -Message ($PSVersionTable.PSVersion) -Verbose
Get-Module -List | Where-Object { $_.Name -eq 'ServerManager' } | Out-String | Write-Verbose -Verbose
Get-WmiObject -List -Class Win32_OptionalFeature | Out-String | Write-Verbose -Verbose
Write-Verbose -Message ('=' * 70) -Verbose

if( $PSVersionTable.PSVersion -gt [Version]'2.0' -and -not (Get-Module -List | Where-Object { $_.Name -eq 'ServerManager' }) -and (Get-WmiObject -List -Class Win32_OptionalFeature) )
{
    Describe 'Test-WindowsFeature' {

        BeforeAll {
            & (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
        }
    
        It 'should detect installed feature' {
            Get-WindowsFeature | 
                Where-Object { $_.Installed } |
                Select-Object -First 1 |
                ForEach-Object {
                    (Test-WindowsFeature -Name $_.Name -Installed) | Should Be $true
                }
        }
    
        It 'should detect uninstalled feature' {
            Get-WindowsFeature | 
                Where-Object { -not $_.Installed } |
                Select-Object -First 1 |
                ForEach-Object {
                    (Test-WindowsFeature -Name $_.Name -Installed) | Should Be $false
                }
        }
    
        It 'should detect features' {
            Get-WindowsFeature |
                Select-Object -First 1 |
                ForEach-Object { (Test-WindowsFeature -Name $_.Name) | Should Be $true }
        }
    
        It 'should not detect feature' {
            (Test-WindowsFeature -Name 'IDoNotExist') | Should Be $false
        }
    }
    
}
else
{
    Write-Warning "Tests for Test-WindowsFeature not supported on this operating system."
}
