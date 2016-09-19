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

Write-Verbose -Message ('=' * 70)
Write-Verbose -Message ($PSVersionTable.PSVersion)
Get-Module -List | Where-Object { $_.Name -eq 'ServerManager' } | Out-String | Write-Verbose
Get-WmiObject -List -Class Win32_OptionalFeature | Out-String | Write-Verbose
Write-Verbose -Message ('=' * 70)

if( $PSVersionTable.PSVersion -gt [Version]'2.0' -and -not (Get-Module -List | Where-Object { $_.Name -eq 'ServerManager' }) -and (Get-WmiObject -List -Class Win32_OptionalFeature) )
{
    $singleFeature = 'TelnetClient'
    $multipleFeatures = @( $singleFeature, 'TFTP' )

    Describe 'Install-WindowsFeature' {

        BeforeAll {
            & (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
        }
    
        BeforeEach {
            Uninstall-WindowsFeature -Name $multipleFeatures
        }
    
        AfterEach {
            Uninstall-WindowsFeature -Name $multipleFeatures
        }
    
        It 'should install windows feature' {
            (Test-WindowsFeature -Name $singleFeature -Installed) | Should Be $false
            Install-WindowsFeature -Name $singleFeature
            (Test-WindowsFeature -Name $singleFeature -Installed) | Should Be $true
        }
    
        It 'should install multiple windows features' {
            (Test-WindowsFeature -Name $multipleFeatures[0] -Installed) | Should Be $false
            (Test-WindowsFeature -Name $multipleFeatures[1] -Installed) | Should Be $false
            Install-WindowsFeature -Name $multipleFeatures
            (Test-WindowsFeature -Name $multipleFeatures[0] -Installed) | Should Be $true
            (Test-WindowsFeature -Name $multipleFeatures[1] -Installed) | Should Be $true
        }
    
        It 'should support what if' {
            Install-WindowsFeature -Name $singleFeature -WhatIf
            (Test-WindowsFeature -Name $singleFeature -Installed) | Should Be $false
        }
    }
}
else
{
    Write-Warning "Tests for Install-WindowsFeature not supported on this operating system."
}