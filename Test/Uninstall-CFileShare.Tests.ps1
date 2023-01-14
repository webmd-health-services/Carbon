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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

if (-not (Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore))
{
    $msgs = 'Get-CFileShare tests will not be run because because the Get-WmiObject command does not exist, which is ' +
            'needed to install a test share.'
    Write-Warning $msgs
    return
}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:shareName = $null
    $script:sharePath = $null
    $script:shareDescription = 'Share for testing Carbon''s Uninstall-CFileShare function.'
}

Describe 'Uninstall-CFileShare' {

    BeforeEach {

        $script:sharePath = Get-Item -Path 'TestDrive:'
        $script:shareName = 'CarbonUninstallFileShare{0}' -f [IO.Path]::GetRandomFileName()
        Install-CFileShare -Path $script:sharePath -Name $script:shareName -Description $script:shareDescription
        Test-CFileShare -Name $script:shareName | Should -BeTrue
        $Global:Error.Clear()
    }

    AfterEach {
        Get-CFileShare -Name $script:shareName -ErrorAction Ignore | Uninstall-CFileShare
    }

    It 'should delete share' {
        $output = Uninstall-CFileShare -Name $script:shareName
        $output | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
        (Test-FileShare -Name $script:shareName) | Should -BeFalse
        $script:sharePath | Should -Exist
    }

    It 'should support should process' {
        $output = Uninstall-CFileShare -Name $script:shareName -WhatIf
        $output | Should -BeNullOrEmpty
        (Test-FileShare -Name $script:shareName) | Should -BeTrue
    }

    It 'should handle share that does not exist' {
        $output = Uninstall-CFileShare -Name 'fdsfdsurwoim'
        $output | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should uninstall file share if share directory does not exist' {
        Remove-Item -Path $script:sharePath
        try
        {
            Uninstall-CFileShare -Name $script:shareName
            $Global:Error | Should -BeNullOrEmpty
            $script:sharePath | Should -Not -Exist
        }
        finally
        {
            New-Item -Path $script:sharePath -ItemType 'Directory'
        }
    }

}
