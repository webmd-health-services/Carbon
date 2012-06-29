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

function Assert-FirewallConfigurable
{
    <#
    .SYNOPSIS
    Asserts that the Windows firewall is configurable and writes an error if it isn't.

    .DESCRIPTION
    The Windows firewall can only be configured if it is running.  This function checks test if it is running.  If it isn't, it writes out an error and returns `False`.  If it is running, it returns `True`.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Assert-FirewallConfigurable

    Returns `True` if the Windows firewall can be configured, `False` if it can't.
    #>
    [CmdletBinding()]
    param(
    )
    if( (Get-Service 'Windows Firewall').Status -ne 'Running' ) 
    {
        Write-Error "Unable to configure firewall: Windows Firewall service isn't running."
        return $false
    }
    return $true
}

function Disable-FirewallStatefulFtp
{
    <#
    .SYNOPSIS
    Disables the `StatefulFtp` Windows firewall setting.

    .DESCRIPTION
    Uses the `netsh` command to disable the `StatefulFtp` Windows firewall setting.

    If the firewall isn't configurable, writes an error and returns without making any changes.

    .LINK
    Assert-FirewallConfigurable

    .EXAMPLE
    Disable-FirewallStatefulFtp
    
    Disables the `StatefulFtp` Windows firewall setting.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    if( -not (Assert-FirewallConfigurable) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( 'firewall', 'disable stateful FTP' ) )
    {
        Write-Host "Disabling stateful FTP in the firewall."
        netsh advfirewall set global StatefulFtp disable
    }
}

function Enable-FirewallStatefulFtp
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    if( -not (Assert-FirewallConfigurable) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( 'firewall', 'enable stateful FTP' ) )
    {
        Write-Host "Enabling stateful FTP in the firewall."
        netsh advfirewall set global StatefulFtp enable
    }
}

function Get-FirewallRules
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
    
      > netsh advfirewall firewall show rule name=all.
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

function Test-FirewallStatefulFtp
{
    [CmdletBinding()]
    param()
    
    if( -not (Assert-FirewallConfigurable) )
    {
        return
    }
    
    $output = netsh advfirewall show global StatefulFtp
    $line = $output[3]
    return $line -match 'Enable'
}
