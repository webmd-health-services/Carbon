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

function Reset-HostsFile
{
    <#
    .SYNOPSIS
    Removes all custom host entries from this computer's hosts file.
    
    .DESCRIPTION
    Sometimes you want to start over.  This method removes all hosts entries from your hosts file after the default localhost entry.
    
    By default, the current computer's hosts file is reset.  You can operate on a custom hosts file by passing its path to the `Path` argument.
    
    .EXAMPLE
    Reset-HostsFile
    
    If your hosts file contains something like this:
    
        127.0.0.1        localhost
        10.1.2.3         myserver
        10.5.6.7         myserver2
        
    After calling `Reset-HostsFile`, your hosts will contain:
    
        127.0.0.1        localhost
      
    
    .EXAMPLE
    Reset-HostsFile -Path my\custom\hosts
    
    Resets the hosts file at `my\custom\hosts`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
       [string]
       # The path to the hosts file to modify.  Defaults to the local computer's hosts file.
       $Path = (Get-PathToHostsFile)
    )

    Set-StrictMode -Version 'Latest'
 
    if(-not (Test-Path $Path) )
    {
       Write-Warning "Creating hosts file '$Path'."
       New-Item $Path -ItemType File
    }
    
    $lines = @( Get-Content -Path $Path )
    $outLines = New-Object System.Collections.ArrayList
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
    
    if( $PSCmdlet.ShouldProcess( $Path, "Reset-HostsFile" ) )
    {
        $outlines | Out-File -FilePath $Path -Encoding OEM
    }     
}
