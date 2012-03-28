# Copyright 2012 Aaron Jensen
# 
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

Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

# Only administratos can update trusted hosts.
if( Test-AdminPrivileges )
{
    $originalTrustedHosts = $null

    function Setup
    {
        $originalTrustedHosts = @( Get-TrustedHosts )
        Set-TrustedHosts
    }

    function TearDown
    {
        Set-TrustedHosts -Entries $originalTrustedHosts
    }

    function Test-ShouldAddNewHost
    {
        Add-TrustedHosts -Entries example.com
        $trustedHosts = @( Get-TrustedHosts )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal ($originalTrustedHosts.Count + 1) $trustedHosts.Count
    }

    function Test-ShouldAddMultipleHosts
    {
        Add-TrustedHosts -Entries example.com,webmd.com
        $trustedHosts = Get-TrustedHosts
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-True ($trustedHosts -contains 'webmd.com')
        Assert-Equal ($originalTrustedHosts.Count + 2) $trustedHosts.Count
    }

    function Test-ShouldNotDuplicateEntries
    {
        Add-TrustedHosts -Entries example.com
        Add-TrustedHosts -Entries example.com
        $trustedHosts = @( Get-TrustedHosts )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal ($originalTrustedHosts.Count + 1) $trustedHosts.Count
    }
    
    function Test-ShouldSupportWhatIf
    {
        Add-TrustedHosts -Entries example.com -WhatIf
        $trustedHosts = @( Get-TrustedHosts )
        Assert-True ($trustedHosts -notcontains 'example.com')
        Assert-Equal $originalTrustedHosts.Count $trustedHosts.Count
        
    }
}
