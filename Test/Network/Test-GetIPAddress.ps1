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

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Get-ExpectedIPAddress
{
    [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | 
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } | 
        ForEach-Object { $_.GetIPProperties() } | 
        Select-Object -ExpandProperty UnicastAddresses  | 
        Select-Object -ExpandProperty Address 
}

function Test-ShouldGetIPAddress
{
    $expectedIPAddress = Get-ExpectedIPAddress
    Assert-NotNull $expectedIPAddress

    $actualIPAddress = Get-IPAddress
    Assert-NotNull $actualIPAddress

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Test-ShouldGetIPv4Addresses
{
    [Object[]]$expectedIPAddress = Get-ExpectedIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetwork' }

    [Object[]]$actualIPAddress = Get-IPAddress -V4

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Test-ShouldGetIPv6Addresses
{
    [Object[]]$expectedIPAddress = Get-ExpectedIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetworkV6' }
    if( -not $expectedIPAddress )
    {
        Write-Warning ('Unable to test if Get-IPAddress returns just IPv6 addresses: there are on IPv6 addresses on this computer.')
        return
    }

    [Object[]]$actualIPAddress = Get-IPAddress -V6

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Assert-IPAddress
{
    param(
        [IPAddress[]]
        $Expected,

        [IPAddress[]]
        $Actual
    )
    Assert-Equal $Expected.Length $Actual.Length 
    for( $idx = 0; $idx -lt $Expected.Length; ++$idx )
    {
        Assert-Equal $Expected[$idx] $Actual[$idx]
    }
}

