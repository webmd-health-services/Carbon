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

function Enable-NtfsCompression
{
    <#
    .SYNOPSIS
    Turns on NTFS compression on a file/directory.

    .DESCRIPTION
    By default, when enabling compression on a directory, only new files/directories created *after* enabling compression will be compressed.  To compress everything, use the `-Recurse` switch.

    Uses Windows' `compact.exe` command line utility to compress the file/directory.  To see the output from `compact.exe`, set the `Verbose` switch.

    .LINK
    Disable-NtfsCompression

    .LINK
    Test-NtfsCompression

    .EXAMPLE
    Enable-NtfsCompression -Path C:\Projects\Carbon

    Turns on NTFS compression on and compresses the `C:\Projects\Carbon` directory, but not its sub-directories.

    .EXAMPLE
    Enable-NtfsCompression -Path C:\Projects\Carbon -Recurse

    Turns on NTFS compression on and compresses the `C:\Projects\Carbon` directory and all its sub-directories.

    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer } | Enable-NtfsCompression

    Demonstrates that you can pipe the path to compress into `Enable-NtfsCompression`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]
        [Alias('FullName')]
        # The path where compression should be enabled.
        $Path,

        [Switch]
        # Enables compression on all sub-directories.
        $Recurse
    )


    begin
    {
        Set-StrictMode -Version 'Latest'

        $commonParams = @{
                            ErrorAction = $ErrorActionPreference;
                            Verbose = $VerbosePreference;
                            WhatIf = $WhatIfPreference;
                        }

        $compactPath = Join-Path $env:SystemRoot 'system32\compact.exe'
        if( -not (Test-Path -Path $compactPath -PathType Leaf) )
        {
            if( (Get-Command -Name 'compact.exe' -ErrorAction SilentlyContinue) )
            {
                $compactPath = 'compact.exe'
            }
            else
            {
                Write-Error ("Compact command '{0}' not found." -f $compactPath)
                return
            }
        }
    }

    process
    {
        foreach( $item in $Path )
        {
            if( -not (Test-Path -Path $item) )
            {
                Write-Error -Message ('Path {0} not found.' -f $item) -Category ObjectNotFound
                return
            }

            $recurseArg = ''
            $pathArg = $item
            if( (Test-Path -Path $item -PathType Container) )
            {
                if( $Recurse )
                {
                    $recurseArg = ('/S:{0}' -f $item)
                    $pathArg = ''
                }
            }
        
            Invoke-ConsoleCommand -Target $item -Action 'enable NTFS compression' @commonParams -ScriptBlock { 
                & $compactPath /C $recurseArg $pathArg
            }
        }
    }
}