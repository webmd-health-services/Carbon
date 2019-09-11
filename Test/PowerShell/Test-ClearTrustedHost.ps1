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

& (Join-Path $TestDir ..\Initialize-CarbonTest.ps1 -Resolve)

# Only administratos can update trusted hosts.
if( Test-AdminPrivilege )
{
    $originalTrustedHosts = $null

    function Start-Test
    {
        $originalTrustedHosts = @( Get-TrustedHost )
    }

    function Stop-Test
    {
        if( $originalTrustedHosts )
        {
            Set-TrustedHost -Entry $originalTrustedHosts
        }
    }

    function Test-ShouldRemoveTrustedHosts
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Clear-TrustedHost
        Assert-Null (Get-TrustedHost)
    }
    
    function Test-ShouldSupportWhatIf
    {
        Set-TrustedHost 'example.com'
        Assert-Equal 'example.com' (Get-TrustedHost)
        Clear-TrustedHost -WhatIf
        Assert-Equal 'example.com' (Get-TrustedHost)
    }
    
        
}
else
{
    Write-Warning "Only Administrators can modify the trusted hosts list."
}

