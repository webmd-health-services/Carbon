
function Add-CTrustedHost
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
    Add-CTrustedHost -Entry example.com

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
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $trustedHosts = @( Get-CTrustedHost )
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
        Set-CTrustedHost -Entry $trustedHosts
    }
}

Set-Alias -Name 'Add-TrustedHosts' -Value 'Add-CTrustedHost'
