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

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldDetectWhenSerivceIsConfigurable
{
    $firewallSvc = Get-Service -Name 'Windows Firewall'
    Assert-NotNull $firewallSvc
    $error.Clear()
    if( $firewallSvc.Status -eq 'Running' )
    {
        $result = Assert-FirewallConfigurable
        Assert-True $result
        Assert-Equal 0 $error.Count
    }
    else
    {
        Write-Warning "Unable to test if Assert-FirewallConfigurable handles when the firewall is configurable: the firewall service is running."
    }
}

function Test-ShouldDetectWhenSerivceIsNotConfigurable
{
    $firewallSvc = Get-Service -Name 'Windows Firewall'
    Assert-NotNull $firewallSvc
    $error.Clear()
    if( $firewallSvc.Status -eq 'Running' )
    {
        Write-Warning "Unable to test if Assert-FirewallConfigurable handles when the firewall is not configurable: the firewall service is not running."
    }
    else
    {
        $result = Assert-FirewallConfigurable -ErrorAction SilentlyContinue
        Assert-False $result
        Assert-Equal 1 $error.Count
    }
}
