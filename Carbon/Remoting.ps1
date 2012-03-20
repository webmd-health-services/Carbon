
function Add-TrustedHosts
{
    <#
    .SYNOPSIS
    Adds an item to the computer's list of trusted hosts.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
        # The computer name(s) to add to the trusted hosts
        $Entries
    )
    
    $trustedHosts = @( Get-TrustedHosts )
    $newEntries = @()
    
    foreach( $entry in $Entries )
    {
        if( $trustedHosts -notcontains $entry )
        {
            $trustedHosts += $entry 
            $newEntries += $entry
        }
    }
    
    if( $pscmdlet.ShouldProcess( "trusted hosts", "adding $( ($newEntries -join ',') )" ) )
    {
        Set-TrustedHosts -Entries $trustedHosts
    }
}

function Get-TrustedHosts
{
    <#
    .SYNOPSIS
    Returns the current computer's trusted hosts list.
    #>
    $trustedHosts = (Get-Item WSMan:\localhost\Client\TrustedHosts -Force).Value 
    if( -not $trustedHosts )
    {
        return @()
    }
    
    return $trustedHosts -split ','
}


function Set-TrustedHosts
{
    <#
    .SYNOPSIS
    Sets the current computer's trusted hosts list.  Overwrites the existing list.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter()]
        [string[]]
        # An array of trusted host entries.
        $Entries = @()
    )
    
    $value = $Entries -join ','
    Set-Item WSMan:\localhost\Client\TrustedHosts -Value $Value -Force
}

