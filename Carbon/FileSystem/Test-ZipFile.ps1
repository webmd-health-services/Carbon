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

function Test-ZipFile
{
    <#
    .SYNOPSIS
    Tests if a file is a ZIP file using the `DotNetZip` library.

    .DESCRIPTION
    Uses the `Ionic.Zip.ZipFile.IsZipFile` static method to determine if a file is a ZIP file.  The file *must* exist. If it doesn't, an error is written and `$null` is returned.

    You can pipe `System.IO.FileInfo` (or strings) to this function to filter multiple items.

    .LINK
    https://www.nuget.org/packages/DotNetZip

    .LINK
    Compress-Item
    
    .LINK
    Expand-Item
    
    .EXAMPLE
    Test-ZipFile -Path 'MyCoolZip.zip'
    
    Demonstrates how to check the current directory if MyCoolZip.zip is really a ZIP file.  
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('FullName')]
        [string]
        # The path to the file to test.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    $Path = Resolve-FullPath -Path $Path
    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Error ('File ''{0}'' not found.' -f $Path)
        return
    }

    return [Ionic.Zip.ZipFile]::IsZipFile( $Path )

}