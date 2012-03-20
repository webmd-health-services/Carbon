
function Assert-WindowsFirewallConfigurable
{
    if( (Get-Service 'Windows Firewall').Status -ne 'Running' ) 
    {
        Write-Error "Unable to configure firewall: Windows Firewall service isn't running."
        return $false
    }
    return $true
}

function Disable-FirewallStatefulFtp
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param()
    
    if( -not (Assert-WindowsFirewallConfigurable) )
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
    
    if( -not (Assert-WindowsFirewallConfigurable) )
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
    
    if( -not (Assert-WindowsFirewallConfigurable) )
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
    
    if( -not (Assert-WindowsFirewallConfigurable) )
    {
        return
    }
    
    $output = netsh advfirewall show global StatefulFtp
    $line = $output[3]
    return $line -match 'Enable'
}