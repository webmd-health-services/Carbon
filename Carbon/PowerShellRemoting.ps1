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

function Add-TrustedHosts
{
    <#
    .SYNOPSIS
    Adds an item to the computer's list of trusted hosts.

    .DESCRIPTION
    Adds an entry to this computer's list of trusted hosts.  If the item already exists, nothing happens.

    PowerShell Remoting needs to be turned on for this function to work.

    .LINK
    Enable-PSRemoting

    .EXAMPLE
    Add-TrustedHosts -Entries example.com

    Adds `example.com` to the list of this computer's trusted hosts.  If `example.com` is already on the list of trusted hosts, nothing happens.
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

    .DESCRIPTION
    PowerShell stores its trusted hosts list as a comma-separated list of hostnames in the `WSMan` drive.  That's not very useful.  This function reads that list, splits it, and returns each item.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Get-TrustedHosts

    If the trusted hosts lists contains `example.com`, `api.example.com`, and `docs.example.com`, returns the following:

        example.com
        api.example.com
        docs.example.com
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

