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

function Install-Junction
{
    <#
    .SYNOPSIS
    Creates a junction, or updates an existing junction if its target is different.
    
    .DESCRIPTION
    Creates a junction given by `-Link` which points to the path given by `-Target`.  If `Link` exists, deletes it and re-creates it if it doesn't point to `Target`.
    
    Both `-Link` and `-Target` parameters accept relative paths for values.  Any non-rooted paths are converted to full paths using the current location, i.e. the path returned by `Get-Location`.

    .LINK
    New-Junction

    .LINK
    Remove-Junction

    .EXAMPLE
    Install-Junction -Link 'C:\Windows\system32Link' -Target 'C:\Windows\system32'
    
    Creates the `C:\Windows\system32Link` directory, which points to `C:\Windows\system32`.

    .EXAMPLE
    Install-Junction -Link C:\Projects\Foobar -Target 'C:\Foo\bar' -Force

    This example demonstrates how to create the target directory if it doesn't exist.  After this example runs, the directory `C:\Foo\bar` and junction `C:\Projects\Foobar` will be created.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The junction to create/update. Relative paths are converted to absolute paths using the current location.
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to.  Relative paths are converted to absolute paths using the curent location.
        $Target,

        [Switch]
        # Create the target directory if it does not exist.
        $Force
    )

    Set-StrictMode -Version Latest

    $Link = Resolve-FullPath -Path $Link
    $Target = Resolve-FullPath -Path $Target

    if( Test-Path -Path $Target -PathType Leaf )
    {
        Write-Error ('Unable to create junction {0}: target {1} exists and is a file.' -f $Link,$Target)
        return
    }

    if( -not (Test-Path -Path $Target -PathType Container) )
    {
        if( $Force )
        {
            $null = New-Item -Path $Target -ItemType Directory -Force
        }
        else
        {
            Write-Error ('Unable to create junction {0}: target {1} not found.  Use the `-Force` switch to create target paths that don''t exist.' -f $Link,$Target)
            return
        }
    }

    if( Test-Path $Link -PathType Container )
    {
        $junction = Get-Item $Link -Force
        if( -not $junction.IsJunction )
        {
            Write-Error ('Failed to create junction ''{0}'': a directory exists with that path and it is not a junction.' -f $Link)
            return
        }

        if( $junction.TargetPath -eq $Target )
        {
            return
        }

        Remove-Junction -Path $Link
    }

    if( $PSCmdlet.ShouldProcess( $Target, ("creating '{0}' junction" -f $Link) ) )
    {
        $null = New-Junction -Link $Link -Target $target
    }
}
