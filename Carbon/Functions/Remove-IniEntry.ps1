
function Remove-CIniEntry
{
    <#
    .SYNOPSIS
    Removes an entry/line/setting from an INI file.
    
    .DESCRIPTION
    A configuration file consists of sections, led by a `[section]` header and followed by `name = value` entries.  This function removes an entry in an INI file.  Something like this:

        [ui]
        username = Regina Spektor <regina@reginaspektor.com>

        [extensions]
        share = 
        extdiff =

    Names are not allowed to contains the equal sign, `=`.  Values can contain any character.  The INI file is parsed using `Split-CIni`.  [See its documentation for more examples.](Split-CIni.html)
    
    If the entry doesn't exist, does nothing.

    Be default, operates on the INI file case-insensitively. If your INI is case-sensitive, use the `-CaseSensitive` switch.

    .LINK
    Set-CIniEntry

    .LINK
    Split-CIni

    .EXAMPLE
    Remove-CIniEntry -Path C:\Projects\Carbon\StupidStupid.ini -Section rat -Name tails

    Removes the `tails` item in the `[rat]` section of the `C:\Projects\Carbon\StupidStupid.ini` file.

    .EXAMPLE
    Remove-CIniEntry -Path C:\Users\me\npmrc -Name 'prefix' -CaseSensitive

    Demonstrates how to remove an INI entry in an INI file that is case-sensitive.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the INI file.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the INI entry to remove.
        $Name,
        
        [string]
        # The section of the INI where the entry should be set.
        $Section,

        [Switch]
        # Removes INI entries in a case-sensitive manner.
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $settings = @{ }
    
    if( Test-Path $Path -PathType Leaf )
    {
        $settings = Split-CIni -Path $Path -AsHashtable -CaseSensitive:$CaseSensitive
    }
    else
    {
        Write-Error ('INI file {0} not found.' -f $Path)
        return
    }

    $key = $Name
    if( $Section )
    {
        $key = '{0}.{1}' -f $Section,$Name
    }

    if( $settings.ContainsKey( $key ) )
    {
        $lines = New-Object 'Collections.ArrayList'
        Get-Content -Path $Path | ForEach-Object { [void] $lines.Add( $_ ) }
        $null = $lines.RemoveAt( ($settings[$key].LineNumber - 1) )
        if( $PSCmdlet.ShouldProcess( $Path, ('remove INI entry {0}' -f $key) ) )
        {
            if( $lines )
            {
                $lines | Set-Content -Path $Path
            }
            else
            {
                Clear-Content -Path $Path
            }
        }
    }

}
