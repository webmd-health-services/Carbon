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

Import-Module -Name (Join-Path -Path $PSScriptRoot -ChildPath 'CarbonDscTest' -Resolve) -Force

$RuleName = 'CarbonDscFirewallRule'

Start-CarbonDscTestFixture 'FirewallRule'

Describe 'Carbon_FirewallRule' {
    
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
            Where-Object { $_.Count -eq 1 } |
            Select-Object -First 1 |
            Select-Object -ExpandProperty 'Group'
    }
    
    BeforeAll {
    }
    
    BeforeEach {
        $Global:Error.Clear()
        Remove-FirewallRule
    }
    
    AfterEach {
        Remove-FirewallRule
    }
    
    AfterAll {
        Stop-CarbonDscTestFixture
    }
    <#
    It 'should get present target resource' {
        # Select a firewall rule that has a unique name.
        $rule = Get-FirewallRuleUnique
    
        $resource = Get-TargetResource -Name $rule.Name -Direction $rule.Direction -Action $rule.Action
        $resource | Should Not BeNullOrEmpty
        foreach( $propName in $resource.Keys )
        {
            if( $propName -eq 'Ensure' )
            {
                continue
            }
            if( $propName -eq 'Profile' )
            {
                $resource[$propName] | ForEach-Object { $rule.Profile.ToString() -match ('{0}' -f $_) }
                if( $rule.Profile -eq [Carbon.Firewall.RuleProfile]::Any )
                {
                    $resource[$propName][0] | Should Be 'Any'
                }
                else
                {
                    [Enum]::GetValues(([Carbon.Firewall.RuleProfile])) | 
                        Where-Object { $_ -ne [Carbon.Firewall.RuleProfile]::Any -and $rule.Profile -band $_ -eq $_ } |
                        ForEach-Object { $resource[$propName] -contains $_.ToString() | Should Be $true } 
                }
            }
            else
            {
                $resource[$propName] | Should Be $rule.$propName
            }
        }
        Assert-DscResourcePresent $resource
    }
    
    It 'should get absent target resource' {
        $resource = Get-TargetResource -Name $RuleName -Direction 'In' -Action 'Allow'
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be $RuleName
        $resource.Direction | Should Be 'In'
        $resource.Action | Should Be 'Allow'
        $resource.Description | Should BeNullOrEmpty
        $resource.EdgeTraversalPolicy | Should Be 'No'
        $resource.Enabled | Should Be $true
        $resource.InterfaceType | Should Be 'Any'
        $resource.LocalIPAddress | Should Be 'Any'
        $resource.LocalPort | Should BeNullOrEmpty
        $resource.Profile | Should Be 'Any'
        $resource.Program | Should BeNullOrEmpty
        $resource.Protocol | Should Be 'Any'
        $resource.RemoteIPAddress | Should Be 'Any'
        $resource.RemotePort | Should BeNullOrEmpty
        $resource.Security | Should Be 'NotRequired'
        $resource.Service | Should BeNullOrEmpty
        Assert-DscResourceAbsent $resource
    }
    
    It 'should get absent target resource uses param values' {
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
        $resource | Should Not BeNullOrEmpty
        $resource.Name | Should Be 'Name'
        $resource.Direction | Should Be 'Out'
        $resource.Action | Should Be 'Block'
        $resource.Description | Should Be 'Description'
        $resource.EdgeTraversalPolicy | Should Be 'Yes'
        $resource.Enabled | Should Be $false
        $resource.InterfaceType | Should Be 'Wireless'
        $resource.LocalIPAddress | Should Be '10.1.2.3'
        $resource.LocalPort | Should Be '6500'
        $resource.Profile | Should Be 'Public'
        $resource.Program | Should Be 'C:\program.exe'
        $resource.Protocol | Should Be 'tcp'
        $resource.RemoteIPAddress | Should Be '192.168.1.1'
        $resource.RemotePort | Should Be '5600'
        $resource.Security | Should Be 'AuthEnc'
        $resource.Service | Should Be 'C:\service.exe'
        Assert-DscResourceAbsent $resource
    }
    
    It 'should test target resource' {
        (Get-FirewallRule -Name $RuleName) | Should BeNullOrEmpty
        (Test-TargetResource -Name $RuleName -Direction In -Action Allow -Ensure Present) | Should Be $false
        (Test-TargetResource -Name $RuleName -Direction In -Action Allow -Ensure Absent) | Should Be $true
        $rule = Get-FirewallRuleUnique
        $rule | Should Not BeNullOrEmpty
        (Test-TargetResource -Name $rule.Name -Direction $rule.Direction -Action $rule.Action -Ensure Present) | Should Be $true
        (Test-TargetResource -Name $rule.Name -Direction $rule.Direction -Action $rule.Action -Ensure Absent) | Should Be $false
    }
    
    It 'should look at each property when testing target resource' {
        netsh advfirewall firewall add rule name=$ruleName dir=in action=allow
        $testParams = @{
                            Name = $ruleName;
                            Direction = 'In';
                            Action = 'Allow';
                            Ensure = 'Present';
                        }
        (Test-TargetResource @testParams) | Should Be $true
        (Test-TargetResource @testParams -Enabled:$false) | Should Be $false
        (Test-TargetResource @testParams -Profile Private) | Should Be $false
        (Test-TargetResource @testParams -LocalIPAddress '10.1.1.2') | Should Be $false
        (Test-TargetResource @testParams -LocalPort '6500') | Should Be $false
        (Test-TargetResource @testParams -RemoteIPAddress '10.2.2.3') | Should Be $false
        (Test-TargetResource @testParams -RemotePort '8700') | Should Be $false
        (Test-TargetResource @testParams -Protocol 'tcp') | Should Be $false
        (Test-TargetResource @testParams -EdgeTraversalPolicy DeferApp) | Should Be $false
        (Test-TargetResource @testParams -InterfaceType LAN) | Should Be $false
        (Test-TargetResource @testParams -Security AuthDynEnc) | Should Be $false
        (Test-TargetResource @testParams -Description 'description') | Should Be $false
        (Test-TargetResource @testParams -Program 'C:\program.exe') | Should Be $false
        (Test-TargetResource @testParams -Service $ruleName) | Should Be $false
    }
    
    It 'should set target resource' {
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
        $rule | Should Not BeNullOrEmpty
        $rule.Enabled | Should Be $false
        $rule.Direction | Should Be 'Out'
        $rule.Profile | Should Be 'Private'
        $rule.LocalIPAddress | Should Be '10.1.2.3/32'
        $rule.LocalPort | Should Be '60543'
        $rule.RemoteIPAddress | Should Be '10.3.2.1/32'
        $rule.RemotePort | Should Be '34556'
        $rule.Protocol | Should Be 'tcp'
        $rule.EdgeTraversalPolicy | Should Be 'No'
        $rule.Action | Should Be 'Block'
        $rule.InterfaceType | Should Be 'LAN'
        $rule.Security | Should Be 'NotRequired'
        $rule.Description | Should Be 'description'
        $rule.Program | Should Be 'C:\program.exe'
        $rule.Service | Should Be $name
    
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
        $rule | Should Not BeNullOrEmpty
        $rule.Enabled | Should Be $true
        $rule.Direction | Should Be 'In'
        $rule.Profile | Should Be 'Public'
        $rule.LocalIPAddress | Should Be '10.4.5.6/32'
        $rule.LocalPort | Should Be '59432'
        $rule.RemoteIPAddress | Should Be '10.6.5.4/32'
        $rule.RemotePort | Should Be '23456'
        $rule.Protocol | Should Be 'udp'
        $rule.EdgeTraversalPolicy | Should Be 'No'
        $rule.Action | Should Be 'Allow'
        $rule.InterfaceType | Should Be 'Wireless'
        $rule.Security | Should Be 'NotRequired'
        $rule.Description | Should Be 'description 2'
        $rule.Program | Should Be 'C:\program2.exe'
        $rule.Service | Should Be ('{0}2' -f $name)
    
        Set-TargetResource -Name $name -Ensure Absent
        (Get-FirewallRule -Name $name) | Should BeNullOrEmpty
    }
    
    It 'should set with defaults' {
        Set-TargetResource -Name $RuleName -Direction In -Action Allow
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Name | Should Be $RuleName
        $rule.Direction | Should Be 'In'
        $rule.Action | Should Be 'Allow'
        $rule.Description | Should BeNullOrEmpty
        $rule.EdgeTraversalPolicy | Should Be 'No'
        $rule.Enabled | Should Be $true
        $rule.InterfaceType | Should Be 'Any'
        $rule.LocalIPAddress | Should Be 'Any'
        $rule.LocalPort | Should BeNullOrEmpty
        $rule.Profile | Should Be 'Domain, Private, Public'
        $rule.Program | Should BeNullOrEmpty
        $rule.Protocol | Should Be 'Any'
        $rule.RemoteIPAddress | Should Be 'Any'
        $rule.RemotePort | Should BeNullOrEmpty
        $rule.Security | Should Be 'NotRequired'
        $rule.Service | Should BeNullOrEmpty
    }
    #>
    
    It 'should set security and edge' {
        # Set a firewall rule with security and edge. Requires inbound rule.
        Set-TargetResource -Name $RuleName -Direction In -Action Allow -Security AuthEnc -EdgeTraversalPolicy Yes -Ensure Present
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Name | Should Be $RuleName
        $rule.Direction | Should Be 'In'
        $rule.Action | Should Be 'Allow'
        netsh advfirewall firewall show rule "name=$RuleName" verbose | 
            Where-Object { $_ -match '\bAuthEnc\b' } |
            Should Not BeNullOrEmpty
        $rule.EdgeTraversalPolicy | Should Be 'Yes'
    
        Set-TargetResource -Name $RuleName -Direction In -Action Allow -Security Authenticate -EdgeTraversalPolicy No -Ensure Present
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        netsh advfirewall firewall show rule "name=$RuleName" verbose | 
            Where-Object { $_ -match '\bAuthenticate\b' } |
            Should Not BeNullOrEmpty
        $rule.EdgeTraversalPolicy | Should Be 'No'
    }
    return
    It 'should require direction and action when adding new rule' {
        Set-TargetResource -Name $RuleName -ErrorAction SilentlyContinue
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match '\bDirection\b.*\bAction\b'
        (Get-FirewallRule -Name $RuleName) | Should BeNullOrEmpty
    }
}

Describe 'Carbon_FirewallRule.when run as a DSC resource' {
    
    $Global:Error.Clear()

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
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Name | Should Be $RuleName
        $rule.Direction | Should Be 'In'
        $rule.Action | Should Be 'Allow'
    
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot 
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should BeNullOrEmpty
    
        $result = Get-DscConfiguration
        $Global:Error.Count | Should Be 0
        $result | Should BeOfType ([Microsoft.Management.Infrastructure.CimInstance])
        $result.PsTypeNames | Where-Object { $_ -like '*Carbon_FirewallRule' } | Should Not BeNullOrEmpty
    }
}

Describe 'Carbon_FirewallRule.when run through DSC with multiple profiles' {

    $Global:Error.Clear()
    $RuleName = 'SupportMultiplePRofiles'
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
                Profile = 'Public','Private'
                Ensure = $Ensure;
            }
        }
    }
    
    It 'should run through dsc' {
        & DscConfiguration -Ensure 'Present' -OutputPath $CarbonDscOutputRoot
        
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
    }

    It 'should set multiple profiles' {
        $rule = Get-FirewallRule -Name $RuleName
        $rule | Should Not BeNullOrEmpty
        $rule.Profile | Should Match '\bPublic\b'
        $rule.Profile | Should Match '\bPrivate\b'
    }

    It 'should remove the rule' {
        & DscConfiguration -Ensure 'Absent' -OutputPath $CarbonDscOutputRoot
        Start-DscConfiguration -Wait -ComputerName 'localhost' -Path $CarbonDscOutputRoot -Force
        $Global:Error.Count | Should Be 0
        Get-FirewallRule -Name $RuleName | Should BeNullOrEmpty
    }

}
