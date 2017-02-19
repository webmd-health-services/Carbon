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
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Test-ShouldGetFirewallRules
{
    [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule
    Assert-NotNull $rules
    Assert-GreaterThan $rules.Count 0 
    
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
            Assert-Like $actualRule.Protocol ('*:{0},{1}' -f $Matches[1],$Matches[2]) ('[{0}] {1}' -f $ruleIdx,$actualRule.Name)
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

        Assert-NotNull ($actualRule | Get-Member $propName) ('property {0} not found on {1} object [{2}] {3}' -f $propName,$actualRule.GetType().FullName,$ruleIdx,$actualRule.Name)
        $value = $actualRule.$propName
        if( $value -is [bool] )
        {
            $value = if( $value ) { 'Yes' } else { 'No' }
        }

        if( $propName -eq 'Protocol' )
        {
            $value = $value -replace ':.*$',''
        }

        Assert-Equal $line ($format -f ('{0}:' -f $fieldName),$value) $ruleIdx
    }
}

function Test-ShouldGetFirewallRule
{
    Get-FirewallRule | ForEach-Object {
        $rule = $_
        $actualRule = Get-FirewallRule -Name $rule.Name | ForEach-Object {
            $actualRule = $_

            Assert-NotNull $actualRule
            Assert-Equal $rule.Name $actualRule.Name
        }
    }
}

function Test-ShouldSupportWildcardFirewallRule
{
    [Carbon.Firewall.Rule[]]$allRules = Get-FirewallRule
    Assert-NotNull $allRules
    [Carbon.Firewall.Rule[]]$rules = Get-FirewallRule -Name '*HTTP*' 
    Assert-NotNull $rules
    Assert-LessThan $rules.Length $allRules.Length
    $expectedCount = netsh advfirewall firewall show rule name=all | Where-Object { $_ -like 'Rule Name*HTTP*' } | Measure-Object | Select-Object -ExpandProperty 'Count'
    Assert-Equal $expectedCount $rules.Length
}

function Test-ShouldSupportLiteralName
{
    $rules = Get-FirewallRule -LiteralName '*HTTP*'
    Assert-Null $rules
}

