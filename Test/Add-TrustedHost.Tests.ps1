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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)

# Only administratos can update trusted hosts.
if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

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

    function Test-ShouldAddNewHost
    {
        Add-TrustedHost -Entries example.com 
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal 1 $trustedHosts.Count
    }

    function Test-ShouldAddMultipleHosts
    {
        Add-TrustedHost -Entry example.com,webmd.com
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-True ($trustedHosts -contains 'webmd.com')
        Assert-Equal 2 $trustedHosts.Count
    }

    function Test-ShouldNotDuplicateEntries
    {
        Add-TrustedHost -Entry example.com
        Add-TrustedHost -Entry example.com
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal 1 $trustedHosts.Count
    }
    
    function Test-ShouldSupportWhatIf
    {
        $preTrustedHosts = @( Get-TrustedHost )
        Add-TrustedHost -Entry example.com -WhatIf
        $trustedHosts = @( Get-TrustedHost )
        Assert-True ($trustedHosts -notcontains 'example.com')
        Assert-Equal $preTrustedHosts.Count $trustedHosts.Count
        
    }
}

