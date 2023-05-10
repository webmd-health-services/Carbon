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

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)
}

Describe 'Get-FirewallRule' {
    It 'should get all firewall rules' -Skip:((Test-Path -Path 'env:WHS_CI') -and $env:WHS_CI -eq 'True') {
        [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule
        $rules | Should -Not -BeNullOrEmpty

        $expectedCount =
            netsh advfirewall firewall show rule name=all verbose |
            Where-Object { $_ -like 'Rule Name:*' } |
            Measure-Object |
            Select-Object -ExpandProperty 'Count'
        $rules.Count | Should -BeGreaterOrEqual $expectedCount
    }

    It 'should get specific firewall rule' {
        Get-FirewallRule |
            Select-Object -First 1 |
            ForEach-Object {
                $rule = $_
                $actualRule = Get-FirewallRule -Name $rule.Name | ForEach-Object {
                    $actualRule = $_

                    $actualRule | Should -Not -BeNullOrEmpty
                    $actualRule.Name | Should -Be $rule.Name
            }
        }
    }

    It 'should get firewall rules using wildcard' {
        [Carbon.Firewall.Rule[]]$allRules = Get-FirewallRule
        $allRules | Should -Not -BeNullOrEmpty
        [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule -Name '*HTTP*'
        $rules | Should -Not -BeNullOrEmpty
        $rules.Length | Should -BeLessThan $allRules.Length
        $expectedCount =
            netsh advfirewall firewall show rule name=all |
            Where-Object { $_ -like 'Rule Name*HTTP*' } |
            Measure-Object |
            Select-Object -ExpandProperty 'Count'
        $rules | Should -HaveCount $expectedCount
    }

    It 'should get firewall rule using literal name' {
        $rules = Get-FirewallRule -LiteralName '*HTTP*'
        $rules | Should -BeNullOrEmpty
    }
}
