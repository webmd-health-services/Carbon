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

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
    $script:shareName = 'CarbonTestFileShare'
    $script:sharePath = $null
    $script:shareDescription = 'Share for testing Carbon''s Get-FileShare function.'

    $script:sharePath = New-CTempDirectory -Prefix $PSCommandPath
    Install-CFileShare -Path $script:sharePath -Name $script:shareName -Description $script:shareDescription
}

AfterAll {
    Uninstall-CFileShare -Name $script:shareName
    Uninstall-CDirectory -Path $script:sharePath
}

Describe 'Test-FileShare' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should test share' {
        $shares = Get-CFileShare
        $shares | Should -Not -BeNullOrEmpty
        $sharesNotFound = $shares | Where-Object { -not (Test-FileShare -Name $_.Name) }
        $sharesNotFound | Should -BeNullOrEmpty
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'should detect shares that do not exist' {
        (Test-CFileShare -Name 'fdjfkdsfjdsf') | Should -BeFalse
        $Global:Error | Should -BeNullOrEmpty
    }
}
