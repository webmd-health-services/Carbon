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

function Add-TrustedHost
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
    Add-TrustedHost -Entry example.com

    Adds `example.com` to the list of this computer's trusted hosts.  If `example.com` is already on the list of trusted hosts, nothing happens.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string[]]
		[Alias("Entries")]
        # The computer name(s) to add to the trusted hosts
        $Entry
    )
    
    $trustedHosts = @( Get-TrustedHost )
    $newEntries = @()
    
	$Entry | ForEach-Object {
		if( $trustedHosts -notcontains $_ )
		{
            $trustedHosts += $_ 
            $newEntries += $_
		}
	}
    
    if( $pscmdlet.ShouldProcess( "trusted hosts", "adding $( ($newEntries -join ',') )" ) )
    {
        Set-TrustedHost -Entry $trustedHosts
    }
}

Set-Alias -Name 'Add-TrustedHosts' -Value 'Add-TrustedHost'