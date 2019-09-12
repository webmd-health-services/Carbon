
function Reset-CHostsFile
{
    <#
    .SYNOPSIS
    Removes all custom host entries from this computer's hosts file.
    
    .DESCRIPTION
    Sometimes you want to start over.  This method removes all hosts entries from your hosts file after the default localhost entry.
    
    By default, the current computer's hosts file is reset.  You can operate on a custom hosts file by passing its path to the `Path` argument.
    
    .EXAMPLE
    Reset-CHostsFile
    
    If your hosts file contains something like this:
    
        127.0.0.1        localhost
        10.1.2.3         myserver
        10.5.6.7         myserver2
        
    After calling `Reset-CHostsFile`, your hosts will contain:
    
        127.0.0.1        localhost
      
    
    .EXAMPLE
    Reset-CHostsFile -Path my\custom\hosts
    
    Resets the hosts file at `my\custom\hosts`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
       [string]
       # The path to the hosts file to modify.  Defaults to the local computer's hosts file.
       $Path = (Get-CPathToHostsFile)
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
 
    if(-not (Test-Path $Path) )
    {
       Write-Warning "Creating hosts file '$Path'."
       New-Item $Path -ItemType File
    }
    
    $cmdErrors = @()
    [string[]]$lines = Read-CFile -Path $Path -ErrorVariable 'cmdErrors'
    if( $cmdErrors )
    {
        return
    }

    $outLines = New-Object -TypeName 'System.Collections.ArrayList'
    foreach($line in $lines)
    {
        if($line.Trim().StartsWith("#") -or ($line.Trim() -eq '') )
        {
            [void] $outlines.Add($line)
        }
        else
        {
            break
        }
    }
    
    [void] $outlines.Add("127.0.0.1       localhost")
    
    if( $PSCmdlet.ShouldProcess( $Path, "Reset-CHostsFile" ) )
    {
        $outlines | Write-CFile -Path $Path
    }     
}

