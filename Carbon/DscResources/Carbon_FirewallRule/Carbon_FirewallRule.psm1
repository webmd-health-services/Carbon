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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([Hashtable])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [bool]
        $Enabled = $true,

        [ValidateSet('In','Out')]
        [string]
        $Direction,

        [ValidateSet('Any','Domain','Private','Public')]
        [string[]]
        $Profile = @( 'Any' ),

        [string]
        $LocalIPAddress = 'Any',

        [string]
        $LocalPort,

        [string]
        $RemoteIPAddress = 'Any',

        [string]
        $RemotePort,

        [string]
        $Protocol = 'Any',

        [ValidateSet('Yes', 'No', 'DeferUser','DeferApp')]
        [string]
        $EdgeTraversalPolicy = 'No',

        [ValidateSet('Allow','Block','Bypass')]
        [string]
        $Action,

        [ValidateSet('Any','Wireless','LAN','RAS')]
        [string]
        $InterfaceType = 'Any',

        [ValidateSet('NotRequired','Authenticate','AuthEnc','AuthDynEnc','AuthNoEncap')]
        [string]
        $Security = 'NotRequired',

        [string]
        $Description,

        [string]
        $Program,

        [string]
        $Service,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $rule = Get-CFirewallRule -LiteralName $Name
    if( $rule -is [object[]] )
    {
        Write-Error ('Found {0} firewall rules named ''{1}''.' -f $rule.Count,$Name)
        return
    }
    
    $resource = @{ 
                    'Action' = $Action;
                    'Description' = $Description;
                    'Direction' = $Direction;
                    'EdgeTraversalPolicy' = $EdgeTraversalPolicy
                    'Enabled' = $Enabled;
                    'Ensure' = 'Absent';
                    'InterfaceType' = $InterfaceType
                    'LocalIPAddress' = $LocalIPAddress;
                    'LocalPort' = $LocalPort;
                    'Name' = $Name;
                    'Profile' = $Profile;
                    'Program' = $Program;
                    'Protocol' = $Protocol;
                    'RemoteIPAddress' = $RemoteIPAddress;
                    'RemotePort' = $RemotePort;
                    'Security' = $Security;
                    'Service' = $Service;
                }

    if( $rule )
    {
        $propNames = $resource.Keys | ForEach-Object { $_ }
        $propNames | 
            Where-Object { $_ -ne 'Ensure' } |
            ForEach-Object { 
                $propName = $_
                switch( $propName )
                {
                    'Profile' { $value = $rule.Profile.ToString() -split ', ' }
                    'Enabled' { $value = $rule.Enabled }
                    default
                    {
                        $value = ($rule.$propName).ToString()
                    }
                }

                $resource[$propName] = $value
            }
        $resource.Ensure = 'Present'
    }

    return $resource
}
 
function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for managing firewall rules.

    .DESCRIPTION
    The `Carbon_FirewallRule` resource manages firewall rules. It uses the `netsh advfirewall firewall` command. Please see [Netsh AdvFirewall Firewall Commands](http://technet.microsoft.com/en-us/library/dd734783.aspx) or run `netsh advfirewall firewall set rule` for documentation on how to configure the firewall.

    When modifying existing rules, only properties you pass are updated/changed. All other properties are left as-is.

    `Carbon_FirewallRule` is new in Carbon 2.0.

    .LINK
    Get-CFirewallRule

    .LINK
    http://technet.microsoft.com/en-us/library/dd734783.aspx

    .EXAMPLE
    >
    Demonstrates how to enable a firewall rule.

        Carbon_FirewallRule EnableHttpIn
        {
            Name = 'World Wide Web Services (HTTP Traffic-In)'
            Enabled = $true;
            Ensure = 'Present'
        }

    .EXAMPLE
    >
    Demonstrates how to delete a firewall rule.

        Carbon_FirewallRule DeleteMyRule
        {
            Name = 'MyCustomRule';
            Ensure = 'Absent';
        }

    There may be multiple rules with the same name, so we recommend disabling rules instead.

    .EXAMPLE
    >
    Demonstrates how to create/modify an incoming firewall rule.

        Carbon_FirewallRule MyAppPorts
        {
            Name = 'My App Ports';
            Action = 'Allow';
            Direction = 'In';
            Protocol = 'tcp';
            LocalPort = '8080,8180';
            Ensure = 'Present';
        }
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the rule.
        $Name,

        [bool]
        # If `$true`, the rule is enabled. If `$false`, the rule is disabled.
        $Enabled = $true,

        [ValidateSet('In','Out')]
        [string]
        # If set to `In`, the rule applies to inbound network traffic. If set to `Out`, the rule applies to outbound traffic.
        $Direction,

        [ValidateSet('Any','Domain','Private','Public')]
        [string[]]
        # Specifies the profile(s) to which the firewall rule is assigned. The rule is active on the local computer only when the specified profile is currently active. Valid values are `Any`, `Domain`, `Public`, and `Private`.
        $Profile,

        [string]
        # The local IP addresses the rule applies to. Valid values are `any`, an exact IPv4 or IPv6 address, a subnet mask (e.g. 192.168.0.0/24), or a range. Separate each value with a comma; no spaces.
        $LocalIPAddress,

        [string]
        # The local port the rule applies to. Valid values are a specific port number, a range of port numbers (e.g. `5000-5010`), a comma-separate list of numbers and ranges, `any`, `rpc`, `rpc-epmap`, `Teredo`, and `iphttps`.
        $LocalPort,

        [string]
        # The remote IP addresses the rules applies to. Valid values are `any`, an exact IPv4 or IPv6 address, a subnet mask (e.g. 192.168.0.0/24), or a range. Separate each value with a comma; no spaces.
        $RemoteIPAddress,

        [string]
        # The remote port the rule applies to. Valid values are a specific port number, a range of port numbers (e.g. `5000-5010`), a comma-separate list of numbers and ranges, `any`, `rpc`, `rpc-epmap`, `Teredo`, and `iphttps`.
        $RemotePort,

        [string]
        # The protocol the rule applies to. Valid values are `any`, the protocol number, `icmpv4`, `icmpv6', `icmpv4:type,code`, `icmpv6:type,code`, `tcp`, or `udp`. Separate multiple values with a comma; no spaces.
        $Protocol,

        [ValidateSet('Yes', 'No', 'DeferUser','DeferApp')]
        [string]
        # For inbound rules, specifies that traffic that traverses an edge device, such as a Network Address Translation (NAT) enabled router, between the local and remote computer matches this rule. Valid values are `any`, `deferapp`, `deferuse`, or `no`.
        $EdgeTraversalPolicy,

        [ValidateSet('Allow','Block','Bypass')]
        [string]
        # Specifies what to do when packets match the rule. Valid values are `Allow`, `Block`, or `Bypass`.
        $Action,

        [ValidateSet('Any','Wireless','LAN','RAS')]
        [string]
        # Specifies that only network packets passing through the indicated interface types match this rule. Valid values are `Any`, `Wireless`, `LAN`, or `RAS`.
        $InterfaceType,

        [ValidateSet('NotRequired','Authenticate','AuthEnc','AuthDynEnc','AuthNoEncap')]
        [string]
        # Specifies that only network packets protected with the specified type of IPsec options match this rule. Valid values are `NotRequired`, `Authenticate`, `AuthEnc`, `AuthDynEnc`, or `AuthNoEncap`.
        $Security,

        [string]
        # A description of the rule.
        $Description,

        [string]
        # Specifies that network traffic generated by the identified executable program matches this rule.
        $Program,

        [string]
        # Specifies that traffic generated by the identified service matches this rule. The ServiceShortName for a service can be found in Services MMC snap-in, by right-clicking the service, selecting Properties, and examining Service Name.
        $Service,

        [ValidateSet('Present','Absent')]
        [string]
        # Set to `Present` to create the fireall rule. Set to `Absent` to delete it.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Name $Name
    if( $Ensure -eq 'Absent' -and $resource.Ensure -eq 'Present' )
    {
        Write-Verbose ('Deleting firewall rule ''{0}''' -f $Name)
        $output = netsh advfirewall firewall delete rule name=$Name
        if( $LASTEXITCODE )
        {
            Write-Error ($output -join ([Environment]::NewLine))
            return
        }
        $output | Write-Verbose
        return
    }

    $cmd = 'add'
    $cmdDisplayName = 'Adding'
    $newArg = ''
    if( $Ensure -eq 'Present' -and $resource.Ensure -eq 'Present' )
    {
        $cmd = 'set'
        $cmdDisplayName = 'Setting'
        $newArg = 'new'
    }
    else
    {
        if( -not $Direction -and -not $Action )
        {
            Write-Error ('Parameters ''Direction'' and ''Action'' are required when adding a new firewall rule.')
            return
        }
        elseif( -not $Direction )
        {
            Write-Error ('Parameter ''Direction'' is required when adding a new firewall rule.')
            return
        }
        elseif( -not $Action )
        {
            Write-Error ('Parameter ''Action'' is required when adding a new firewall rule.')
            return
        }
    }

    $argMap = @{
                    'Direction' = 'dir';
                    'Enabled' = 'enable';
                    'LocalIPAddress' = 'localip';
                    'RemoteIPAddress' = 'remoteip';
                    'EdgeTraversalPolicy' = 'edge';
              }

    $netshArgs = New-Object 'Collections.Generic.List[string]'
    $resource.Keys |
        Where-Object { $_ -ne 'Ensure' -and $_ -ne 'Name' } |
        Where-Object { $PSBoundParameters.ContainsKey($_) } |
        ForEach-Object {
            $argName = $_.ToLowerInvariant()
            $argValue = $PSBoundParameters[$argName]
            if( $argValue -is [bool] )
            {
                $argValue = if( $argValue ) { 'yes' } else { 'no' }
            }
            if( $argMap.ContainsKey($argName) )
            {
                $argName = $argMap[$argName]
            }
            if( $argName -eq 'Profile' )
            {
                $argValue = $argValue -join ','
            }

            [void]$netshArgs.Add( ('{0}=' -f $argName) )
            [void]$netshArgs.Add( $argValue )
        }
    
    Write-Verbose ('{0} firewall rule ''{1}'': cmd= {2}; name= {3}; newArg: {4}; netshargs= {5}' -f $cmdDisplayName,$Name,$cmd,$Name,$newArg,($netshArgs -join ' '))
    Write-Debug -Message ('cmd= {0}; name= {1}; newArg: {2}; netshargs= {3}' -f $cmd,$Name,$newArg,($netshArgs -join ' '))
    $output = netsh advfirewall firewall $cmd rule name= $Name $newArg $netshArgs 
    if( $LASTEXITCODE )
    {
        Write-Error ($output -join ([Environment]::NewLine))
        return
    }
    $output | Write-Verbose
}

function Test-TargetResource
{
    [CmdletBinding()]
    [OutputType([bool])]
    param (
        [Parameter(Mandatory=$true)]
        [string]
        $Name,

        [bool]
        $Enabled,

        [ValidateSet('In','Out')]
        [string]
        $Direction,

        [ValidateSet('Any','Domain','Private','Public')]
        [string[]]
        $Profile,

        [string]
        $LocalIPAddress,

        [string]
        $LocalPort,

        [string]
        $RemoteIPAddress,

        [string]
        $RemotePort,

        [string]
        $Protocol,

        [ValidateSet('Yes', 'No', 'DeferUser','DeferApp')]
        [string]
        $EdgeTraversalPolicy,

        [ValidateSet('Allow','Block','Bypass')]
        [string]
        $Action,

        [ValidateSet('Any','Wireless','LAN','RAS')]
        [string]
        $InterfaceType,

        [ValidateSet('NotRequired','Authenticate','AuthEnc','AuthDynEnc','AuthNoEncap')]
        [string]
        $Security,

        [string]
        $Description,

        [string]
        $Program,

        [string]
        $Service,

        [ValidateSet('Present','Absent')]
        [string]
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource @PSBoundParameters
    if( $Ensure -eq 'Absent' )
    {
        $result = ($resource.Ensure -eq 'Absent')
        if( $result )
        {
            Write-Verbose ('Firewall rule ''{0}'' not found.' -f $Name)
        }
        else
        {
            Write-Verbose ('Firewall rule ''{0}'' found.' -f $Name)
        }
        return $result
    }

    if( $Ensure -eq 'Present' -and $resource.Ensure -eq 'Absent' )
    {
        Write-Verbose ('Firewall rule ''{0}'' not found.' -f $Name)
        return $false
    }

    return Test-CDscTargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('Firewall rule ''{0}''' -f $Name)
}



