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

function Test-ShouldTestExistingIPV4Address
{
    Get-IPAddress -V4 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_) }
}

function Test-ShouldTestExistingIPV4String
{
    Get-IPAddress -V4 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_.ToString()) }
}

function Test-ShouldTestNonExistentIPV4Address
{
    Assert-False (Test-IPAddress -IPAddress ([Net.IPAddress]::Parse('255.255.255.0')))
}

function Test-ShouldTestNonExistentIPV4String
{
    Assert-False (Test-IPAddress -IPAddress '255.255.255.0')
}


function Test-ShouldHandleExistentIPV6Address
{
    Get-IPAddress -V6 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_ ) }
}

function Test-ShouldHandleExistentIPV6String
{
    Get-IPAddress -V6 | ForEach-Object { Assert-True (Test-IPAddress -IPAddress $_.ToString() ) }
}

function Test-ShouldHandleNonExistentIP6Address
{
    Assert-False (Test-IPAddress -IPAddress ([Net.IPAddress]::Parse('::1')))
}

function Test-ShouldHandleNonExistentIPV6String
{
    Assert-False (Test-IPAddress -IPAddress '::1')
}

