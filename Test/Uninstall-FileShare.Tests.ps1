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

Describe 'Uninstall-FileShare' {
    $shareName = $null
    $sharePath = $null
    $shareDescription = 'Share for testing Carbon''s Uninstall-FileShare function.'

    BeforeEach {
        $Global:Error.Clear()

        $sharePath = Get-Item -Path 'TestDrive:' 
        $shareName = 'CarbonUninstallFileShare{0}' -f [IO.Path]::GetRandomFileName()
        Install-SmbShare -Path $sharePath -Name $shareName -Description $shareDescription
        (Test-FileShare -Name $shareName) | Should Be $true
    }
    
    AfterEach {
        Get-FileShare -Name $shareName -ErrorAction Ignore | ForEach-Object { $_.Delete() }
    }
    
    It 'should delete share' {
        $output = Uninstall-FileShare -Name $shareName
        $output | Should BeNullOrEmpty
        $Global:Error.Count | Should Be 0
        (Test-FileShare -Name $shareName) | Should Be $false
        $sharePath | Should Exist
    }
    
    It 'should support should process' {
        $output = Uninstall-FileShare -Name $shareName -WhatIf
        $output | Should BeNullOrEmpty
        (Test-FileShare -Name $shareName) | Should Be $true
    }
    
    It 'should handle share that does not exist' {
        $output = Uninstall-FileShare -Name 'fdsfdsurwoim'
        $output | Should BeNullOrEmpty
        $Global:Error.Count | Should Be 0
    }

    It 'should uninstall file share if share directory does not exist' {
        Remove-Item -Path $sharePath
        try
        {
            Uninstall-FileShare -Name $shareName
            $Global:Error.Count | Should Be 0
            $sharePath | Should Not Exist
        }
        finally
        {
            New-Item -Path $sharePath -ItemType 'Directory'
        }
    }
    
}
