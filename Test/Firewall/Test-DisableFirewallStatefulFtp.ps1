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

$alreadyEnabled = $false

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonTest.ps1' -Resolve)
}

function Start-Test
{
    $alreadyEnabled = Test-FirewallStatefulFtp
    
    if( -not $alreadyEnabled )
    {
        Enable-FirewallStatefulFtp
    }
}

function Stop-Test
{
    if( $alreadyEnabled )
    {
        Enable-FirewallStatefulFtp
    }
    else
    {
        Disable-FirewallStatefulFtp
    }
}

function Test-ShouldDisableStatefulFtp
{
    Disable-FirewallStatefulFtp
    $enabled = Test-FirewallStatefulFtp
    Assert-False $enabled 'StatefulFtp not enabled on firewall.'
}

function Test-ShouldSupportWhatIf
{
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFTP not enabled'
    Disable-FirewallStatefulFtp -WhatIf
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFTP disable with -WhatIf parameter given.'
}

