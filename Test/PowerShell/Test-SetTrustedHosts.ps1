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

& (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)

# Only administratos can update trusted hosts.
if( Test-AdminPrivileges )
{
    $originalTrustedHosts = $null

    function Setup
    {
        $originalTrustedHosts = @( Get-TrustedHosts )
        Clear-TrustedHosts
    }

    function TearDown
    {
        if( $originalTrustedHosts )
        {
            Set-TrustedHosts -Entries $originalTrustedHosts
        }
    }

    function Test-ShouldSetTrustedHosts
    {
        Set-TrustedHosts 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHosts)
        Set-TrustedHosts 'example.com','sub.example.com'
        $hosts = @( Get-TrustedHosts )
        Assert-Equal 'example.com' $hosts[0]
        Assert-Equal 'sub.example.com' $hosts[1]
    }

    function Test-ShouldSupportWhatIf
    {
        Set-TrustedHosts 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHosts)
        Set-TrustedHosts 'badexample.com' -WhatIf
        Assert-Equal 'example.com' (Get-TrustedHosts)
    }
}
