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

# Only administratos can update trusted hosts.
if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
    }

    function Start-Test
    {
        $originalTrustedHosts = @( Get-TrustedHost )
        Clear-TrustedHost
    }

    function Stop-Test
    {
        if( $originalTrustedHosts )
        {
            Set-TrustedHost -Entry $originalTrustedHosts
        }
    }

    function Test-ShouldSetTrustedHosts
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Set-TrustedHost 'example.com','sub.example.com'
        $hosts = @( Get-TrustedHost )
        Assert-Equal 'example.com' $hosts[0]
        Assert-Equal 'sub.example.com' $hosts[1]
    }

    function Test-ShouldSupportWhatIf
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Set-TrustedHost 'badexample.com' -WhatIf
        Assert-Equal 'example.com' (Get-TrustedHost)
    }
}

