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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest.psm1' -Resolve) -Force
$RuleName = 'CarbonDscFirewallRule'

function Start-TestFixture
{
    Start-CarbonDscTestFixture 'FirewallRule'
}

function Start-Test
{
    Remove-FirewallRule
}

function Stop-Test
{
    Remove-FirewallRule
}

function Stop-TestFixture
{
    Stop-CarbonDscTestFixture
}

function Test-ShouldGetPresentTargetResource
{
    # Select a firewall rule that has a unique name.
    $rule = Get-FirewallRuleUnique

    $resource = Get-TargetResource -Name $rule.Name -Direction $rule.Direction -Action $rule.Action
    Assert-NotNull $resource
    foreach( $propName in $resource.Keys )
    {
        if( $propName -eq 'Ensure' )
        {
            continue
        }
        Assert-Equal $rule.$propName $resource[$propName] ('{0}: {1}' -f $rule.Name,$propName)
    }
    Assert-DscResourcePresent $resource
}

function Test-ShouldGetAbsentTargetResource
{
    $resource = Get-TargetResource -Name $RuleName -Direction 'In' -Action 'Allow'
    Assert-NotNull $resource
    Assert-Equal $RuleName $resource.Name
    Assert-Equal 'In' $resource.Direction
    Assert-Equal 'Allow' $resource.Action
    Assert-Empty $resource.Description
    Assert-Equal 'No' $resource.EdgeTraversalPolicy
    Assert-True $resource.Enabled
    Assert-Equal 'Any' $resource.InterfaceType
    Assert-Equal 'Any' $resource.LocalIPAddress
    Assert-Empty $resource.LocalPort
    Assert-Equal 'Any' $resource.Profile
    Assert-Empty $resource.Program
    Assert-Equal 'Any' $resource.Protocol
    Assert-Equal 'Any' $resource.RemoteIPAddress
    Assert-Empty $resource.RemotePort
    Assert-Equal 'NotRequired' $resource.Security
    Assert-Empty $resource.Service
    Assert-DscResourceAbsent $resource
}

function Test-ShouldGetAbsentTargetResourceUsesParamValues
{
    $resource = Get-TargetResource -Name 'Name' `
                                   -Direction Out `
                                   -Action Block `
                                   -Enabled:$false `
                                   -Profile Public `
                                   -LocalIPAddress '10.1.2.3' `
                                   -LocalPort '6500' `
                                   -RemoteIPAddress '192.168.1.1' `
                                   -RemotePort '5600' `
                                   -Protocol 'tcp' `
                                   -EdgeTraversalPolicy Yes `
                                   -InterfaceType Wireless `
                                   -Security AuthEnc `
                                   -Description 'description' `
                                   -Program 'C:\program.exe' `
                                   -Service 'C:\service.exe' `
                                   -Ensure Present
    Assert-NotNull $resource
    Assert-Equal 'Name' $resource.Name
    Assert-Equal 'Out' $resource.Direction
    Assert-Equal 'Block' $resource.Action
    Assert-Equal 'Description' $resource.Description
    Assert-Equal 'Yes' $resource.EdgeTraversalPolicy
    Assert-False $resource.Enabled
    Assert-Equal 'Wireless' $resource.InterfaceType
    Assert-Equal '10.1.2.3' $resource.LocalIPAddress
    Assert-Equal '6500' $resource.LocalPort
    Assert-Equal 'Public' $resource.Profile
    Assert-Equal 'C:\program.exe' $resource.Program
    Assert-Equal 'tcp' $resource.Protocol
    Assert-Equal '192.168.1.1' $resource.RemoteIPAddress
    Assert-Equal '5600' $resource.RemotePort
    Assert-Equal 'AuthEnc' $resource.Security
    Assert-Equal 'C:\service.exe' $resource.Service
    Assert-DscResourceAbsent $resource
}

function Test-ShouldTestTargetResource
{
    Assert-Null (Get-FirewallRule -Name $RuleName)
    Assert-False (Test-TargetResource -Name $RuleName -Direction In -Action Allow -Ensure Present)
    Assert-True (Test-TargetResource -Name $RuleName -Direction In -Action Allow -Ensure Absent)
    $rule = Get-FirewallRuleUnique
    Assert-NotNull $rule
    Assert-True (Test-TargetResource -Name $rule.Name -Direction $rule.Direction -Action $rule.Action -Ensure Present)
    Assert-False (Test-TargetResource -Name $rule.Name -Direction $rule.Direction -Action $rule.Action -Ensure Absent)
}

function Test-ShouldLookAtEachPropertyWhenTestingTargetResource
{
    netsh advfirewall firewall add rule name=$ruleName dir=in action=allow
    $testParams = @{
                        Name = $ruleName;
                        Direction = 'In';
                        Action = 'Allow';
                        Ensure = 'Present';
                    }
    Assert-True (Test-TargetResource @testParams)
    Assert-False (Test-TargetResource @testParams -Enabled:$false)
    Assert-False (Test-TargetResource @testParams -Profile Private)
    Assert-False (Test-TargetResource @testParams -LocalIPAddress '10.1.1.2')
    Assert-False (Test-TargetResource @testParams -LocalPort '6500')
    Assert-False (Test-TargetResource @testParams -RemoteIPAddress '10.2.2.3')
    Assert-False (Test-TargetResource @testParams -RemotePort '8700')
    Assert-False (Test-TargetResource @testParams -Protocol 'tcp')
    Assert-False (Test-TargetResource @testParams -EdgeTraversalPolicy DeferApp)
    Assert-False (Test-TargetResource @testParams -InterfaceType LAN)
    Assert-False (Test-TargetResource @testParams -Security AuthDynEnc)
    Assert-False (Test-TargetResource @testParams -Description 'description')
    Assert-False (Test-TargetResource @testParams -Program 'C:\program.exe')
    Assert-False (Test-TargetResource @testParams -Service $ruleName)
}

function Test-ShouldSetTargetResource
{
    $name = $RuleName

    Set-TargetResource -Name $name `
                        -Enabled:$false `
                        -Direction Out `
                        -Action Block `
                        -Profile Private `
                        -LocalIPAddress '10.1.2.3' `
                        -LocalPort '60543' `
                        -Protocol 'tcp' `
                        -RemoteIPAddress '10.3.2.1' `
                        -RemotePort '34556' `
                        -InterfaceType LAN `
                        -Description 'description' `
                        -Program 'C:\program.exe' `
                        -Service $name `
                        -Ensure Present

    $rule = Get-FirewallRule -Name $name
    Assert-NotNull $rule
    Assert-False $rule.Enabled
    Assert-Equal 'Out' $rule.Direction
    Assert-Equal 'Private' $rule.Profile
    Assert-Equal '10.1.2.3/32' $rule.LocalIPAddress
    Assert-Equal '60543' $rule.LocalPort
    Assert-Equal '10.3.2.1/32' $rule.RemoteIPAddress
    Assert-Equal '34556' $rule.RemotePort
    Assert-Equal 'tcp' $rule.Protocol
    Assert-Equal 'No' $rule.EdgeTraversalPolicy
    Assert-Equal 'Block' $rule.Action
    Assert-Equal 'LAN' $rule.InterfaceType
    Assert-Equal 'NotRequired' $rule.Security
    Assert-Equal 'description' $rule.Description
    Assert-Equal 'C:\program.exe' $rule.Program
    Assert-Equal $name $rule.Service

    # Now, let's ensure we can change things
    Set-TargetResource -Name $name `
                        -Enabled:$true `
                        -Direction In `
                        -Action Allow `
                        -Profile Public `
                        -LocalIPAddress '10.4.5.6' `
                        -LocalPort '59432' `
                        -Protocol 'udp' `
                        -RemoteIPAddress '10.6.5.4' `
                        -RemotePort '23456' `
                        -InterfaceType Wireless `
                        -Description 'description 2' `
                        -Program 'C:\program2.exe' `
                        -Service ('{0}2' -f $name) `
                        -Ensure Present

    $rule = Get-FirewallRule -Name $name
    Assert-NotNull $rule
    Assert-True $rule.Enabled
    Assert-Equal 'In' $rule.Direction
    Assert-Equal 'Public' $rule.Profile
    Assert-Equal '10.4.5.6/32' $rule.LocalIPAddress
    Assert-Equal '59432' $rule.LocalPort
    Assert-Equal '10.6.5.4/32' $rule.RemoteIPAddress
    Assert-Equal '23456' $rule.RemotePort
    Assert-Equal 'udp' $rule.Protocol
    Assert-Equal 'No' $rule.EdgeTraversalPolicy
    Assert-Equal 'Allow' $rule.Action
    Assert-Equal 'Wireless' $rule.InterfaceType
    Assert-Equal 'NotRequired' $rule.Security
    Assert-Equal 'description 2' $rule.Description
    Assert-Equal 'C:\program2.exe' $rule.Program
    Assert-Equal ('{0}2' -f $name) $rule.Service

    Set-TargetResource -Name $name -Ensure Absent
    Assert-Null (Get-FirewallRule -Name $name)
}

function Test-ShouldSetWithDefaults
{
    Set-TargetResource -Name $RuleName -Direction In -Action Allow
    $rule = Get-FirewallRule -Name $RuleName
    Assert-NotNull $rule
    Assert-Equal $RuleName $rule.Name
    Assert-Equal 'In' $rule.Direction
    Assert-Equal 'Allow' $rule.Action
    Assert-Empty $rule.Description
    Assert-Equal 'No' $rule.EdgeTraversalPolicy
    Assert-True $rule.Enabled
    Assert-Equal 'Any' $rule.InterfaceType
    Assert-Equal 'Any' $rule.LocalIPAddress
    Assert-Empty $rule.LocalPort
    Assert-Equal 'Domain, Private, Public' $rule.Profile
    Assert-Empty $rule.Program
    Assert-Equal 'Any' $rule.Protocol
    Assert-Equal 'Any' $rule.RemoteIPAddress
    Assert-Empty $rule.RemotePort
    Assert-Equal 'NotRequired' $rule.Security
    Assert-Empty $rule.Service
}


function Test-ShouldSetSecurityAndEdge
{
    # Set a firewall rule with security and edge. Requires inbound rule.
    Set-TargetResource -Name $RuleName -Direction In -Action Allow -Security AuthEnc -EdgeTraversalPolicy Yes -Ensure Present
    $rule = Get-FirewallRule -Name $RuleName
    Assert-NotNull $rule
    Assert-Equal $RuleName $rule.Name
    Assert-Equal 'In' $rule.Direction
    Assert-Equal 'Allow' $rule.Action
    Assert-Equal 'AuthEnc' $rule.Security
    Assert-Equal 'Yes' $rule.EdgeTraversalPolicy

    Set-TargetResource -Name $RuleName -Direction In -Action Allow -Security Authenticate -EdgeTraversalPolicy No -Ensure Present
    $rule = Get-FirewallRule -Name $RuleName
    Assert-NotNull $rule
    Assert-Equal 'Authenticate' $rule.Security
    Assert-Equal 'No' $rule.EdgeTraversalPolicy
}

function Test-ShouldRequireDirectionAndActionWhenAddingNewRule
{
    Set-TargetResource -Name $RuleName -ErrorAction SilentlyContinue
    Assert-Error -Last -Regex '\bDirection\b.*\bAction\b'
    Assert-Null (Get-FirewallRule -Name $RuleName)
}

configuration DscConfiguration
{
    param(
        $Ensure
    )

    Set-StrictMode -Off

    Import-DscResource -Name '*' -Module 'Carbon'

    node 'localhost'
    {
        Carbon_FirewallRule set
        {
            Name = $RuleName;
            Direction = 'In';
            Action = 'Allow';
            Ensure = $Ensure;
        }
    }
}

function Test-ShouldRunThroughDsc
{
    & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
    
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError

    $rule = Get-FirewallRule -Name $RuleName
    Assert-NotNull $rule
    Assert-Equal $RuleName $rule.Name
    Assert-Equal 'In' $rule.Direction
    Assert-Equal 'Allow' $rule.Action

    & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
    Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
    Assert-NoError

    $rule = Get-FirewallRule -Name $RuleName
    Assert-Null $rule

}

function Remove-FirewallRule
{
    param(
        $Name = $RuleName
    )

    if( Get-FirewallRule -Name $Name )
    {
        netsh advfirewall firewall delete rule name=$Name
    }
}

function Get-FirewallRuleUnique
{
    [OutputType([Carbon.Firewall.Rule])]
    param(
    )

    Get-FirewallRule | 
        Group-Object -Property 'Name' | 
        Sort-Object -Property 'Count' | 
        Select-Object -First 1 |
        Select-Object -ExpandProperty 'Group'
}