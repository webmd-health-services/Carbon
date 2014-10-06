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

function Set-HostsEntry
{
    <#
    .SYNOPSIS
    Sets a hosts entry in a hosts file.
    
    .DESCRIPTION
    Sets the IP address for a given hostname.  If the hostname doesn't exist in the hosts file, appends a new entry to the end.  If the hostname does exist, its IP address gets updated.  If you supply a description, it is appended to the line as a comment.
    
    If any duplicate hosts entries are found, they are commented out; Windows uses the first duplicate entry.
    
    This function scans the entire hosts file.  If you have a large hosts file, and are updating multiple entries, this function will be slow.
    
    You can operate on a custom hosts file, too.  Pass its path with the `Path` parameter.

    Sometimes the system's hosts file is in use and locked when you try to update it. The `Set-HostsEntry` function tries 10 times to set a hosts entry before giving up and writing an error. It waits a random amount of time (from 0 to 1000 milliseconds) between each attempt.
    
    .EXAMPLE
    Set-HostsEntry -IPAddress 10.2.3.4 -HostName 'myserver' -Description "myserver's IP address"
    
    If your hosts file contains the following:
    
        127.0.0.1  localhost
        
    After running this command, it will contain the following:
    
        127.0.0.1        localhost
        10.2.3.4         myserver	# myserver's IP address

    .EXAMPLE        
    Set-HostsEntry -IPAddress 10.5.6.7 -HostName 'myserver'
    
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
        [ValidatePattern('\A(?:\b(?:(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\.){3}(?:25[0-5]|2[0-4][0-9]|1[0-9][0-9]|[1-9]?[0-9])\b)\Z')]
        [string]
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
        $Path = (Get-PathToHostsFile)
    )
 
    $matchPattern = '^(?<IP>[0-9a-f.:]+)\s+(?<HostName>[^\s#]+)(?<Tail>.*)$'  
    $lineFormat = "{0,-16}{1}{2}"
    
    if(-not (Test-Path $Path))
    {
        Write-Warning "Creating hosts file at: $Path"
        New-Item $Path -ItemType File
    }
     
    $lines = @( Get-Content -Path $Path )
    $outLines = New-Object System.Collections.ArrayList
    $found = $false
    $lineNum = 0
     
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
            if($HostName -eq $hn)
            {
                if($found)
                {
                    #this is a duplicate so, let's comment it out
                    [void] $outlines.Add("#$line")
                    continue
                }
                $ip = $IPAddress
                $tail = if( $Description ) { "`t# $Description" } else { '' }
                $found = $true   
            }
           
            if($tail.Trim() -eq "#")
            {
                $tail = ""
            }
           
            $outline = $lineformat -f $ip, $hn, $tail
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
       [void] $outlines.Add($outline)
    }
    
    if( $pscmdlet.ShouldProcess( $Path, "set hosts entry $HostName to point to $IPAddress" ) )
    {
        $succeeded = $false
        $maxTries = 10
        $rng = New-Object 'Random'
        for( $idx = 0; $idx -lt $maxTries; ++$idx )
        {
            $exception = $false
            try
            {
                $setHostsEntryError = @()
                $outlines | Out-File -FilePath $Path -Encoding OEM -ErrorAction SilentlyContinue -ErrorVariable 'setHostsEntryError'
                $succeeded = $true
                break
            }
            catch
            {
                if( $Global:Error.Count -gt 0 )
                {
                    $Global:Error.RemoveAt(0)
                }
                $exception = $true
            }

            if( $exception -or $setHostsEntryError )
            {
                $timeout = $rng.Next(0,1000)
                Write-Verbose ('Failed to set hosts entry ''{0}    {1}'' in ''{2}'': waiting {3} milliseconds to try again.' -f $HostName,$IPAddress,$Path,$timeout)
                Start-Sleep -Milliseconds $timeout
            }
        }

        if( -not $succeeded )
        {
            Write-Error ('Failed to set hosts entry ''{0}    {1}'' in ''{2}'': looks like the hosts file is in use.' -f $HostName,$IPAddress,$Path)
        }
        
    }     
}
