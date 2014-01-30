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

function Remove-HostsEntry
{
    <#
    .SYNOPSIS
    Removes entries from the hosts file by hostname.

    .DESCRIPTION
    You can remove multiple entries or pipe entries into this function.

    .EXAMPLE
    Remove-HostsEntry -HostName 'adadvisor.net'

    Demonstrates how to remove hosts entry for `adadvisor.net`, which you probably don't want to do.

    .EXAMPLE
    Remove-HostsEntry -HostName 'adadvisor.net','www.adchimp.com'

    Demonstrates how to remove multiple hosts entries.

    .EXAMPLE
    ('adadvisor.net','www.adchimp.com') | Remove-HostsEntry

    Demonstrates how to pipe hostnames into `Remove-HostsEntry`.

    .EXAMPLE
    Remove-HostsEntry -HostName 'adadvisor.net' -Path 'C:\Projects\Carbon\adblockhosts'

    Demonstrates how to work with a file other than Windows' default hosts file.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,Position=0)]
        [string[]]
        # The hostname of the hosts entry/entries to remove.
        $HostName,

        [string]
        # The hosts file to modify.  Defaults to the Windows hosts file.
        $Path = (Join-Path -Path $env:SystemRoot -ChildPath 'System32\drivers\etc\hosts' -Resolve)
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        $allHostNames = New-Object 'Collections.ArrayList'
    }

    process
    {
        $HostName | 
            ForEach-Object { [Text.RegularExpressions.Regex]::Escape( $_ ) } |
            ForEach-Object { [void] $allHostNames.Add( $_ ) }
    }

    end
    {
        $regex = $allHostNames -join '|'
        $regex = '^[0-9a-f.:]+\s+\b({0})\b.*$' -f $regex 

        $newHostsFile = Get-Content -Path $Path |
                            Where-Object { $_ -notmatch $regex }

        $entryNoun = 'entry'
        if( $HostName.Count -gt 1 )
        {
            $entryNoun = 'entries'
        }

        if( $PSCmdlet.ShouldProcess( $Path, ('removing hosts {0} {1}' -f $entryNoun,($HostName -join ', ')) ) )
        {
            Set-Content -Path $Path -Value $newHostsFile
        }
    }
}