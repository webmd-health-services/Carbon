
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
}

function Test-ShouldGetFirewallRules
{
    $rules = Get-FirewallRules
    Assert-NotNull $rules
    Assert-GreaterThan $rules.Count 0 
    
    $expectedRules = netsh advfirewall firewall show rule name=all
    
    $expectedIdx = 1
    $ruleNum = 1
    $format = "{0,-38}{1}"
    foreach( $actualRule in $rules )
    {
        $name = if($actualRule.Name) { $actualRule.Name } else {' '}
        $ruleID = "for rule $ruleNum`: $($actualRule.Name) [$expectedIdx]"
        Assert-Equal $expectedRules[$expectedIdx] ($format -f 'Rule Name:',$name) $ruleID
        $enabled = if( $actualRule.Enabled ) { 'Yes' } else { 'No' }
        Assert-Equal $expectedRules[$expectedIdx + 2] ($format -f 'Enabled:',$enabled) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + 3] ($format -f 'Direction:',$actualRule.Direction) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + 4] ($format -f 'Profiles:',$actualRule.Profiles) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + 5] ($format -f 'Grouping:',$actualRule.Grouping) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + 6] ($format -f 'LocalIP:',$actualRule.LocalIP) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + 7] ($format -f 'RemoteIP:',$actualRule.RemoteIP) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + 8] ($format -f 'Protocol:',$actualRule.Protocol) $ruleID
        $localPortOffset = 9
        $edgeTraversalOffset = 11
        $nextRuleOffset = 14
        $expectedLocalPort = $expectedRules[$expectedIdx + $localPortOffset]
        if( $expectedLocalPort -like 'LocalPort:*' )
        {
            Assert-Equal $expectedLocalPort ($format -f 'LocalPort:',$actualRule.LocalPort) $ruleID
            Assert-Equal $expectedRules[$expectedIdx + 10] ($format -f 'RemotePort:',$actualRule.RemotePort) $ruleID
        }
        elseif( $expectedLocalPort -like ($format -f '','*') )
        {
        }
        else
        {
            $edgeTraversalOffset = 9
            $nextRuleOffset = 12
        }
        
        Assert-Equal $expectedRules[$expectedIdx + $edgeTraversalOffset] ($format -f 'Edge traversal:',$actualRule.EdgeTraversal) $ruleID
        Assert-Equal $expectedRules[$expectedIdx + $edgeTraversalOffset + 1] ($format -f 'Action:',$actualRule.Action) $ruleID
        $expectedIdx += $nextRuleOffset
        $ruleNum += 1
    }
}
