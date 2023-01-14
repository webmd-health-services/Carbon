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
    $script:shareName = 'CarbonGetFileShare'
    $script:sharePath = $null
    $script:shareDescription = 'Share for testing Carbon''s Get-FileShare function.'

    $script:sharePath = New-CTempDirectory -Prefix $PSCommandPath
    Install-SmbShare -Path $script:sharePath -Name $script:shareName -Description $script:shareDescription

    function Assert-CarbonShare
    {
        param(
            $Share
        )
        $Share | Should -Not -BeNullOrEmpty
        $Share.Description | Should -Be $script:shareDescription
        $Share.Path | Should -Be $script:sharePath.FullName
    }
}

AfterAll {
    $share = Invoke-CPrivateCommand -Name 'Get-CCimInstance' -Parameter @{Class = 'Win32_Share'; Filter = "Name='$script:shareName'"}
    if ($null -ne $share)
    {
        [void] $share.Delete()
    }

    Remove-Item -Path $script:sharePath
}

Describe 'Test-GetFileShare' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should get permissions' {
        $shares = Get-CFileShare
        $shares | Should -Not -BeNullOrEmpty
        $shares | Where-Object { $_.Name -eq $script:shareName }
    }

    It 'should get specific share' {
        $carbonShare = Get-CFileShare -Name $script:shareName
        Assert-CarbonShare $carbonShare
    }

    It 'should get only file shares' {
        $nonFileShares =
            Invoke-CPrivateCommand -Name 'Get-CCimInstance' -Parameter @{Class = 'Win32_Share'} |
            Where-Object 'Type' -NE 0 |
        Where-Object 'Type' -NE 2147483648
        if( $nonFileShares )
        {
            foreach( $nonFileShare in $nonFileShares )
            {
                $share = Get-CFileShare | Where-Object { $_.Name -eq $nonFileShare.Name }
                $share | Should -BeNullOrEmpty
            }
        }
        else
        {
            Write-Warning ('No non-file shares on this computer.')
        }
    }

    It 'should accept wildcards' {
        $carbonShare = Get-CFileShare 'CarbonGetFile*'
        Assert-CarbonShare $carbonShare
    }

    It 'should write error when share not found' {
        $share = Get-CFileShare -Name 'fjdksdfjsdklfjsd' -ErrorAction SilentlyContinue
        $Global:Error | Should -Not -BeNullOrEmpty
        $Global:Error[0] | Should -Match 'not found'
        $share | Should -BeNullOrEmpty
    }

    It 'should not write error if no wildcard matches' {
        $carbonShare = Get-CFileShare 'fjdskfsdf*'
        $Global:Error | Should -BeNullOrEmpty
        $carbonShare | Should -BeNullOrEmpty
    }

    It 'should ignore errors' {
        Get-CFileShare -Name 'fhsdfsdfhsdfsdaf' -ErrorAction Ignore
        $Global:Error | Should -BeNullOrEmpty
    }
}
