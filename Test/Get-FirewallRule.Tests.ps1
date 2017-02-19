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

& (Join-Path -Path $PSScriptRoot 'Import-CarbonForTest.ps1' -Resolve)

Describe 'Get-FirewallRule.when getting all rules' {
    It 'should get firewall rules' {
        [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule
        $rules | Should Not BeNullOrEmpty
        $rules.Count | Should BeGreaterThan 0
        
        $expectedRules = netsh advfirewall firewall show rule name=all verbose
        
        $fieldMaps =    @{
                            'Rule Name' = 'Name';
                            'Edge traversal' = 'EdgeTraversal';
                            'InterfaceTypes' = 'InterfaceType';
                            'Rule source' = 'Source';
                        }
    
        $ruleIdx = 0
        $actualRule = $null
        $format = "{0,-38}{1}"
        for( $idx = 0; $idx -lt $expectedRules.Count; ++$idx )
        {
            $line = $expectedRules[$idx]
            if( -not $line -or $line -match '^\-+$' -or $line -eq 'Ok.' )
            {
                continue
            }
    
            if( $line -match '^ +Type +Code *$' )
            {
                $line = $expectedRules[++$idx]
                if( $line -notmatch '^ +?([^ ]+) +?([^ ]+) *$' )
                {
                    Fail ('Failed to parse protocol details on line {0}: {1}' -f $idx,$line)
                }
                ($actualRule.Protocol -like ('*:{0},{1}' -f $Matches[1],$Matches[2])) | Should Be $true
                continue
            }
    
            if( $line -notmatch ('^(.+?):' ) )
            {
                Fail ('Found misshappen line {0}' -f $line)
            }
    
            $fieldName = $Matches[1]
            $propName = $fieldName
            if( $fieldMaps.ContainsKey($propName) )
            {
                $propName = $fieldMaps[$fieldName]
            }
    
            if( $propName -eq 'Name' )
            {
                $actualRule = $rules[$ruleIdx++]
            }
    
            ($actualRule | Get-Member $propName) | Should Not BeNullOrEmpty
            $value = $actualRule.$propName
            if( $value -is [bool] )
            {
                $value = if( $value ) { 'Yes' } else { 'No' }
            }
    
            if( $propName -eq 'Protocol' )
            {
                $value = $value -replace ':.*$',''
            }

            if( $propname -eq 'Description' )
            {
                $value = $value -replace "’","'"
            }
    
            ($format -f ('{0}:' -f $fieldName),$value) | Should Be $line
        }
    }
 }

 Describe 'Get-FirewallRule.when getting a specific rule' {
    It 'should get firewall rule' {
        Get-FirewallRule | ForEach-Object {
            $rule = $_
            $actualRule = Get-FirewallRule -Name $rule.Name | ForEach-Object {
                $actualRule = $_
    
                $actualRule | Should Not BeNullOrEmpty
                $actualRule.Name | Should Be $rule.Name
            }
        }
    }
}

Describe 'Get-FirewallRule.when getting a specific rule with a wildcard pattern' {
    It 'should support wildcard firewall rule' {
        [Carbon.Firewall.Rule[]]$allRules = Get-FirewallRule
        $allRules | Should Not BeNullOrEmpty
        [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule -Name '*HTTP*' 
        $rules | Should Not BeNullOrEmpty
        $rules.Length | Should BeLessThan $allRules.Length
        $expectedCount = netsh advfirewall firewall show rule name=all | Where-Object { $_ -like 'Rule Name*HTTP*' } | Measure-Object | Select-Object -ExpandProperty 'Count'
        $rules.Length | Should Be $expectedCount
    }
 }

 Describe 'Get-FirewallRule.when getting a specific rule with a literal name' {
    It 'should support literal name' {
        $rules = Get-FirewallRule -LiteralName '*HTTP*'
        $rules | Should BeNullOrEmpty
    }
}
