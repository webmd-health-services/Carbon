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
    Describe 'Get-WindowsFeature' {

        BeforeAll {
            & (Join-Path -Path $PSScriptRoot -ChildPath 'Import-CarbonForTest.ps1' -Resolve)
        }
    
        It 'should return all windows features' {
            $featuresWithoutDisplayNames = @{ 
                                                WindowsRemoteManagement = $true;
                                                OEMHelpCustomization = $true;
                                                CorporationHelpCustomization = $true;
                                            }
            $features = Get-WindowsFeature
            $features | Should Not BeNullOrEmpty
            ($features.Length -gt 1) | Should Be $true
            $features | ForEach-Object {
                $_.Installed | Should Not BeNullOrEmpty
                $_.Name | Should Not BeNullOrEmpty
                if( $featuresWithoutDisplayNames.ContainsKey( $_.Name ) )
                {
                    $_.DisplayName | Should BeNullOrEmpty
                }
                else
                {
                    $_.DisplayName | Should Not BeNullOrEmpty
                }
            }
        }
    
        It 'should return specific feature' {
            Get-WindowsFeature | ForEach-Object {
                $expectedFeature = $_
                $feature = Get-WindowsFeature -Name $expectedFeature.Name
                $feature | Should Not BeNullOrEmpty
                $feature.Name | Should Be $expectedFeature.Name
                $feature.DisplayName | Should Be $expectedFeature.DisplayName
                $feature.Installed | Should Be $expectedFeature.Installed
            }
        }
    
        It 'should return wildcard matches' {
            $features = Get-WindowsFeature -Name *msmq*
            $features | Should Not BeNullOrEmpty
            $features | ForEach-Object {
                $_.Installed | Should Not BeNullOrEmpty
                $_.Name | Should Not BeNullOrEmpty
                ($_.Name -like '*msmq*') | Should Be $true
                $_.DisplayName | Should Not BeNullOrEmpty
            }
        }
    }    
}
else
{
    Write-Warning "Tests for Get-WindowsFeature not supported on this operating system."
}
