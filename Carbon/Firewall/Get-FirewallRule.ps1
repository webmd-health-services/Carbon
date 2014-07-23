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

function Get-FirewallRule
{
    <#
    .SYNOPSIS
    Gets the local computer's firewall rules.
    
    .DESCRIPTION
    Returns a `Carbon.Firewall.Rule` object for each firewall rule on the local computer. 
    
    This data is parsed from the output of:
    
        netsh advfirewall firewall show rule name=all.

    You can return specific rule(s) using the `Name` or `LiteralName` parameters. The `Name` parameter accepts wildcards; `LiteralName` does not. There can be multiple firewall rules with the same name.

    If the firewall isn't configurable/running, writes an error and returns without returning any objects.

    .OUTPUTS
    Carbon.Firewall.Rule.

    .LINK
    Assert-FirewallConfigurable

    .EXAMPLE
    Get-FirewallRule

    Demonstrates how to get the firewall rules running on the current computer.

    .EXAMPLE
    Get-FirewallRule -Name 'World Wide Web Services (HTTP Traffic-In)'

    Demonstrates how to get a specific rule.

    .EXAMPLE
    Get-FirewallRule -Name '*HTTP*'

    Demonstrates how to use wildcards to find rules whose names match a wildcard pattern, in this case any rule whose name contains the text 'HTTP' is returned.

    .EXAMPLE
    Get-FirewallRule -LiteralName 'Custom Rule **CREATED BY AUTOMATED PROCES'

    Demonstrates how to find a specific firewall rule by name if that name has wildcard characters in it.
    #>
    [CmdletBinding(DefaultParameterSetName='All')]
    [OutputType([Carbon.Firewall.Rule])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByName')]
        [string]
        # The name of the rule. Wildcards supported. Names aren't unique, so you may still get back multiple rules
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='ByLiteralName')]
        [string]
        # The literal name of the rule. Wildcards not supported.
        $LiteralName
    )

    Set-StrictMode -Version 'Latest'
    
    if( -not (Assert-FirewallConfigurable) )
    {
        return
    }

    $containsWildcards = $false
    $nameArgValue = 'all'
    if( $PSCmdlet.ParameterSetName -eq 'ByName' )
    {
        $containsWildcards = [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Name) 
        if( -not $containsWildcards )
        {
            $nameArgValue = $Name
        }
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'ByLiteralName' )
    {
        $nameArgValue = $LiteralName
    }

    # Don't change/move this. It's so we can detect if we've parsed a rule.
    $rule = $null

    $fieldMap = @{
                    'Rule name' = 'Name';
                    'Enabled' = 'Enabled';
                    'Direction' = 'Direction';
                    'Profiles' = 'Profiles';
                    'Grouping' = 'Grouping';
                    'LocalIP' = 'LocalIPAddress';
                    'RemoteIP' = 'RemoteIPAddress';
                    'Protocol' = 'Protocol';
                    'LocalPort' = 'LocalPort';
                    'RemotePort' = 'RemotePort';
                    'Edge traversal' = 'EdgeTraversal';
                    'InterfaceTypes' = 'InterfaceType';
                    'Security' = 'Security';
                    'Rule source' = 'Source';
                    'Action' = 'Action';
                    'Description' = 'Description';
                    'Program' = 'Program';
                    'Service' = 'Service';
                }

    $parsingProtocolTypeCode = $false
    netsh advfirewall firewall show rule name=$nameArgValue verbose | ForEach-Object {
        $line = $_
        
        Write-Verbose $line

        if( -not $line -and $rule )
        {
            $profiles = [Carbon.Firewall.RuleProfile]::Any
            $rule.Profiles -split ',' | ForEach-Object { $profiles = $profiles -bor ([Carbon.Firewall.RuleProfile]$_) }
            $constructorArgs = @(
                                    $rule.Name,
                                    $rule.Enabled,
                                    $rule.Direction,
                                    $profiles,
                                    $rule.Grouping,
                                    $rule.LocalIPAddress,
                                    $rule.LocalPort,
                                    $rule.RemoteIPAddress,
                                    $rule.RemotePort,
                                    $rule.Protocol,
                                    $rule.EdgeTraversal,
                                    $rule.Action,
                                    $rule.InterfaceType,
                                    $rule.Security,
                                    $rule.Source,
                                    $rule.Description,
                                    $rule.Program,
                                    $rule.Service
                                )
            New-Object -TypeName 'Carbon.Firewall.Rule' -ArgumentList $constructorArgs
            return
        }

        if( $line -match '^ +Type +Code *$' )
        {
            $parsingProtocolTypeCode = $true
            return
        }

        if( $parsingProtocolTypeCode )
        {
            $parsingProtocolTypeCode = $false
            if( $line -notmatch '^ +?([^ ]+) +?([^ ]+) *$' )
            {
                Write-Warning ('Failed to parse protocol type/code for rule {0}' -f $rule.Name)
                return
            }
            $rule.Protocol = '{0}:{1},{2}' -f $rule.Protocol,$Matches[1],$Matches[2]
        }
        
        if( $line -notmatch '^([^:]+): +(.*)$' )
        {
            return
        }
        
        $propName = $matches[1]
        $value = $matches[2]
        if( -not $fieldMap.ContainsKey( $propName ) )
        {
            Write-Warning ('Unknown field ''{0}'' for rule ''{1}'' in `netsh advfirewall firewall show rule` output.' -f $propName,$rule.Name)
            return
        }
        
        $propName = $fieldMap[$propName]
        if( $propName -eq 'Name' )
        {
            $rule = New-Object 'PsObject'
            foreach( $item in $fieldMap.Values )
            {
                Add-Member -InputObject $rule -MemberType NoteProperty -Name $item -Value $null
            }
            $rule.InterfaceType = [Carbon.Firewall.RuleInterfaceType]::Any
            $rule.Security = [Carbon.Firewall.RuleSecurity]::NotRequired
        }

        if( $propName -eq 'Enabled' )
        {
            $value = if( $value -eq 'No' ) { $false } else { $value }
            $value = if( $value -eq 'Yes' ) { $true } else { $value }
        }
        
        $rule.$propName = $value
    } |
    Where-Object { 
        -not $containsWildcards -or $_.Name -like $Name 
    }
}

Set-Alias -Name 'Get-FirewallRules' -Value 'Get-FirewallRule'