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

function Compress-Item
{
    <#
    .SYNOPSIS
    Compresses a file/directory using the `DotNetZip` library.

    .DESCRIPTION
    You can supply a destination file path, via the `OutFile` parameter. If the file doesn't exist, it is created. If it exists, use the `-Force` parameter to overwrite it.

    Each item added to the ZIP file will be added to the root of the file, with a name matching the original file's/directory's name. For example, if adding the file `C:\Projects\Carbon\RELEASE NOTE.txt`, it would get added to the ZIP file as `RELEASE NOTES.txt`.

    If you don't supply an output file path, one will be created in the current user's TEMP directory.

    A `System.IO.FileInfo` object is returned representing the ZIP file.

    Microsoft's DSC Local Configuration Manager is unable to unzip files compressed with the `DotNetZip` library (or the `ZipFile` class in .NET 4.5), so as an alternative, if you specify the `UseShell` switch, the file will be compressed with the Windows COM shell API.

    .LINK
    https://www.nuget.org/packages/DotNetZip

    .LINK
    Expand-Item

    .LINK
    Test-ZipFile

    .EXAMPLE
    Compress-Item -Path 'C:\Projects\Carbon' -OutFile 'C:\Carbon.zip'

    Demonstrates how to create a ZIP file of the `C:\Projects\Carbon` directory.

    .EXAMPLE
    Get-ChildItem -Path 'C:\Projects\Carbon' | Where-Object { $_.PsIsContainer} | Compress-Item -OutFile 'C:\Projects\Carbon.zip'

    Demonstrates how you can pipe items to `Compress-Item` for compressing.

    .EXAMPLE
    Compress-Item -Path 'C:\Projects\Carbon' -OutFile 'C:\Carbon.zip' -UseShell

    Demonstrates how to create a ZIP file with the Windows shell COM APIs instead of the `DotNetZip` library.
    #>
    [OutputType([IO.FileInfo])]
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
        [Alias('FullName')]
        [string[]]
        # The path to the files/directories to compress.
        $Path,

        [string]
        # Path to destination ZIP file. If not provided, a ZIP file will be created in the current user's TEMP directory.
        $OutFile,

        [Switch]
        # Uses the Windows COM shell API to create the zip file instead of the `DotNetZip` library. Microsoft's DSC Local Configuration Manager can't unzip files zipped with `DotNetZip` (or even the .NET 4.5 `ZipFile` class).
        $UseShell,

        [Switch]
        # Overwrites an existing ZIP file.
        $Force
    )

    begin
    {
        Set-StrictMode -Version 'Latest'

        $zipFile = $null

        if( $OutFile )
        {
            $OutFile = Resolve-FullPath -Path $OutFile
            if( (Test-Path -Path $OutFile -PathType Leaf) )
            {
                if( -not $Force )
                {
                    Write-Error ('File ''{0}'' already exists. Use the `-Force` switch to overwrite.' -f $OutFile)
                    return
                }
            }
        }
        else
        {
            $OutFile = 'Carbon+Compress-Item-{0}.zip' -f ([IO.Path]::GetRandomFileName())
            $OutFile = Join-Path -Path $env:TEMP -ChildPath $OutFile
        }

        if( $UseShell )
        {
            [byte[]]$data = New-Object byte[] 22
            $data[0] = 80
            $data[1] = 75
            $data[2] = 5
            $data[3] = 6
            [IO.File]::WriteAllBytes($OutFile, $data)

            $shellApp = New-Object -ComObject "Shell.Application"
            $copyHereFlags = (
                                0x4 -bor `   # No dialog
                                0x10 -bor `  # Responde "Yes to All" to any prompts
                                0x400        # Do not display a user interface if an error occurs
                            )
            $zipFile = $shellApp.NameSpace($OutFile) 
        }
        else
        {
            $zipFile = New-Object 'Ionic.Zip.ZipFile'
        }

    }

    process
    {
        if( -not $zipFile )
        {
            return
        }

        $Path | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath' | ForEach-Object { 
            $zipEntryName = Split-Path -Leaf -Path $_
            if( $PSCmdlet.ShouldProcess( $_, ('compress to {0} as {1}' -f $OutFile,$zipEntryName)) )
            {
                if( $UseShell )
                {
                    $zipFile.CopyHere($_, $copyHereFlags)
                }
                else
                {
                    if( Test-Path -Path $_ -PathType Container )
                    {
                        [void]$zipFile.AddDirectory( $_, $zipEntryName )
                    }
                    else
                    {
                        [void]$zipFile.AddFile( $_, '.' )
                    }
                }
            }
        }

    }

    end
    {
        if( -not $zipFile )
        {
            return
        }

        if( $UseShell )
        {
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($zipFile)
            [void][Runtime.InteropServices.Marshal]::ReleaseComObject($shellApp)
            while( $true )
            {
                Start-Sleep -Milliseconds 100
                try
                {
                    $file = [IO.File]::Open($OutFile, 'Open', 'Read', 'None')
                    $file.Close()
                    break
                }
                catch
                {
                }
            }
        }
        else
        {
            if( $PSCmdlet.ShouldProcess( $OutFile, 'saving' ) )
            {
                $zipFile.Save( $OutFile )
            }
            $zipFile.Dispose()
        }

        Get-Item -Path $OutFile
    }
}