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

function Start-Test
{
    & (Join-Path -Path $TestDir -ChildPath ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function Stop-Test
{
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
    $expectedIPAddress = Get-ExpectedIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
    $expectedAddress = [Object[]]$expectedIPAddress

    $actualIPAddress = Get-IPAddress -V4
    $actualIPAddress = [Object[]]$actualIPAddress

    Assert-IPAddress $expectedIPAddress $actualIPAddress
}

function Test-ShouldGetIPv6Addresses
{
    $expectedIPAddress = Get-ExpectedIPAddress | Where-Object { $_.AddressFamily -eq 'InterNetworkV6' }
    $expectedAddress = [Object[]]$expectedIPAddress

    $actualIPAddress = Get-IPAddress -V6
    $actualIPAddress = [Object[]]$actualIPAddress

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