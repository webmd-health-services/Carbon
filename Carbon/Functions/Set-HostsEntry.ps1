
function Set-CHostsEntry
{
    <#
    .SYNOPSIS
    Sets a hosts entry in a hosts file.
    
    .DESCRIPTION
    Sets the IP address for a given hostname.  If the hostname doesn't exist in the hosts file, appends a new entry to the end.  If the hostname does exist, its IP address gets updated.  If you supply a description, it is appended to the line as a comment.
    
    If any duplicate hosts entries are found, they are commented out; Windows uses the first duplicate entry.
    
    This function scans the entire hosts file.  If you have a large hosts file, and are updating multiple entries, this function will be slow.
    
    You can operate on a custom hosts file, too.  Pass its path with the `Path` parameter.

    Sometimes the system's hosts file is in use and locked when you try to update it. The `Set-CHostsEntry` function tries 10 times to set a hosts entry before giving up and writing an error. It waits a random amount of time (from 0 to 1000 milliseconds) between each attempt.
    
    .EXAMPLE
    Set-CHostsEntry -IPAddress 10.2.3.4 -HostName 'myserver' -Description "myserver's IP address"
    
    If your hosts file contains the following:
    
        127.0.0.1  localhost
        
    After running this command, it will contain the following:
    
        127.0.0.1        localhost
        10.2.3.4         myserver	# myserver's IP address

    .EXAMPLE        
    Set-CHostsEntry -IPAddress 10.5.6.7 -HostName 'myserver'
    
    If your hosts file contains the following:
    
        127.0.0.1        localhost
        10.2.3.4         myserver	# myserver's IP address
    
    After running this command, it will contain the following:
    
        127.0.0.1        localhost
        10.5.6.7         myserver
    
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [Net.IPAddress]
        # The IP address for the hosts entry.
        $IPAddress,

        [Parameter(Mandatory=$true)]
        [string]
        # The hostname for the hosts entry.
        $HostName,

        [string]
        # An optional description of the hosts entry.
        $Description,

        [string]
        # The path to the hosts file where the entry should be set. Defaults to the local computer's hosts file.
        $Path = (Get-CPathToHostsFile)
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
 
    $matchPattern = '^(?<IP>[0-9a-f.:]+)\s+(?<HostName>[^\s#]+)(?<Tail>.*)$'  
    $lineFormat = "{0,-45}  {1}{2}"
    
    if(-not (Test-Path $Path))
    {
        Write-Warning "Creating hosts file at: $Path"
        New-Item $Path -ItemType File
    }
    
    [string[]]$lines = Read-CFile -Path $Path -ErrorVariable 'cmdErrors'
    if( $cmdErrors )
    {
        return
    }    
    
    $outLines = New-Object 'Collections.ArrayList'
    $found = $false
    $lineNum = 0
    $updateHostsFile = $false
     
    foreach($line in $lines)
    {
        $lineNum += 1
        
        if($line.Trim().StartsWith("#") -or ($line.Trim() -eq '') )
        {
            [void] $outlines.Add($line)
        }
        elseif($line -match $matchPattern)
        {
            $ip = $matches["IP"]
            $hn = $matches["HostName"]
            $tail = $matches["Tail"].Trim()
            if( $HostName -eq $hn )
            {
                if($found)
                {
                    #this is a duplicate so, let's comment it out
                    [void] $outlines.Add("#$line")
                    $updateHostsFile = $true
                    continue
                }
                $ip = $IPAddress
                $tail = if( $Description ) { "`t# $Description" } else { '' }
                $found = $true   
            }
            else
            {
                $tail = "`t{0}" -f $tail
            }
           
            if( $tail.Trim() -eq "#" )
            {
                $tail = ""
            }

            $outline = $lineformat -f $ip, $hn, $tail
            $outline = $outline.Trim()
            if( $outline -ne $line )
            {
                $updateHostsFile = $true
            }

            [void] $outlines.Add($outline)
                
        }
        else
        {
            Write-Warning ("Hosts file {0}: line {1}: invalid entry: {2}" -f $Path,$lineNum,$line)
            $outlines.Add( ('# {0}' -f $line) )
        }

    }
     
    if(-not $found)
    {
       #add a new entry
       $tail = "`t# $Description"
       if($tail.Trim() -eq "#")
       {
           $tail = ""
       }
           
       $outline = $lineformat -f $IPAddress, $HostName, $tail
       $outline = $outline.Trim()
       [void] $outlines.Add($outline)
       $updateHostsFile = $true
    }

    if( -not $updateHostsFile )
    {
        return
    }
    
    Write-Verbose -Message ('[HOSTS]  [{0}]  {1,-45}  {2}' -f $Path,$IPAddress,$HostName)
    $outLines | Write-CFile -Path $Path
}

