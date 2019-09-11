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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$svcName = 'Windows Firewall'
if( -not (Get-Service -Name $svcName -ErrorAction Ignore) )
{
    $svcName = 'Windows Defender Firewall'
}

if( -not (Get-Service -Name $svcName -ErrorAction Ignore) )
{
    Describe 'Assert-FirewallConfigurable' {
        It 'should have a firewall service' {
            $false | Should -BeTrue -Because ('unable to find the firewall service')
        }
    }
    return
}

Describe 'Assert-FirewallConfigurable' {
    It 'should detect when serivce is configurable' {
        $firewallSvc = Get-Service -Name $svcName
        $firewallSvc | Should -Not -BeNullOrEmpty
        $error.Clear()
        if( $firewallSvc.Status -eq 'Running' )
        {
            $result = Assert-FirewallConfigurable
            $result | Should -Be $true
            $error.Count | Should -Be 0
        }
        else
        {
            Write-Warning "Unable to test if Assert-FirewallConfigurable handles when the firewall is configurable: the firewall service is not running."
        }
    }
    
    It 'should detect when serivce is not configurable' {
        $firewallSvc = Get-Service -Name $svcName
        $firewallSvc | Should -Not -BeNullOrEmpty
        $error.Clear()
        if( $firewallSvc.Status -eq 'Running' )
        {
            Write-Warning "Unable to test if Assert-FirewallConfigurable handles when the firewall is not configurable: the firewall service is running."
        }
        else
        {
            $result = Assert-FirewallConfigurable -ErrorAction SilentlyContinue
            $result | Should -Be $false
            $error.Count | Should -Be 1
        }
    }
    
}
