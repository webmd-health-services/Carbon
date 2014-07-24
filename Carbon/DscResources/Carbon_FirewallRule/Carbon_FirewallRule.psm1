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

    $rule = Get-FirewallRule -LiteralName $Name
    
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
                    'Profile' { $value = $rule.Profile.ToString() -split ',' }
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
    [CmdletBinding()]
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

            [void]$netshArgs.Add( ('{0}=' -f $argName) )
            [void]$netshArgs.Add( $argValue )
        }
    
    Write-Verbose ('{0} firewall rule ''{1}''' -f $cmdDisplayName,$Name)
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

        [Parameter(Mandatory=$true)]
        [ValidateSet('Present','Absent')]
        [string]
        $Ensure
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

    return Test-DscTargetResource -TargetResource $resource -DesiredResource $PSBoundParameters -Target ('Firewall rule ''{0}''' -f $Name)
}


