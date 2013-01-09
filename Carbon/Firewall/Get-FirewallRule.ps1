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
    Returns the computer's list of firewall rules.
    
    .DESCRIPTION
    Sends objects down the pipeline for each of the firewall's rules. Each 
    object contains the following properties:
    
      * Name
      * Enabled
      * Direction
      * Profiles
      * Grouping
      * LocalIP
      * RemoteIP
      * Protocol
      * LocalPort
      * RemotePort
      * EdgeTraversal
      * Action
    
    This data is parsed from the output of:
    
        netsh advfirewall firewall show rule name=all.

    If the firewall isn't configurable, writes an error and returns without returning any objects.

    .LINK
    Assert-FirewallConfigurable

    .EXAMPLE
    Get-FirewallRule

    Here's a sample of the output:

        EdgeTraversal : Defer to application
        Grouping      : Remote Assistance
        Action        : Allow
        RemotePort    : Any
        RemoteIP      : Any
        LocalIP       : Any
        Name          : Remote Assistance (PNRP-In)
        Direction     : In
        Profiles      : Domain,Private
        LocalPort     : 3540
        Protocol      : UDP
        Enabled       : True

        EdgeTraversal : No
        Grouping      : Remote Assistance
        Action        : Allow
        RemotePort    : Any
        RemoteIP      : Any
        LocalIP       : Any
        Name          : Remote Assistance (PNRP-Out)
        Direction     : Out
        Profiles      : Domain,Private
        LocalPort     : Any
        Protocol      : UDP
        Enabled       : True

    #>
    param()
    
    if( -not (Assert-FirewallConfigurable) )
    {
        return
    }

    $rule = $null    
    netsh advfirewall firewall show rule name=all | ForEach-Object {
        $line = $_
        
        if( -not $line -and $rule )
        {
            New-Object PsObject -Property $rule
            return
        }
        
        if( $line -notmatch '^([^:]+): +(.*)$' )
        {
            return
        }
        
        $name = $matches[1]
        $value = $matches[2]
        if( $name -eq 'Rule Name' )
        {
            $rule = @{ }
            $name = 'Name'
        }
        elseif( $name -eq 'Edge traversal' )
        {
            $name = 'EdgeTraversal' 
        }

        if( $name -eq 'Enabled' )
        {
            $value = if( $value -eq 'No' ) { $false } else { $value }
            $value = if( $value -eq 'Yes' ) { $true } else { $value }
        }
        
        $rule[$name] = $value
    }
}

Set-Alias -Name 'Get-FirewallRules' -Value 'Get-FirewallRule'