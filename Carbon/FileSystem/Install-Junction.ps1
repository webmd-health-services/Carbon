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
    
    .LINK
    New-Junction

    .LINK
    Remove-Junction

    .EXAMPLE
    Install-Junction -Link 'C:\Windows\system32Link' -Target 'C:\Windows\system32'
    
    Creates the `C:\Windows\system32Link` directory, which points to `C:\Windows\system32`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The junction to create/update.
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to.d
        $Target
    )

    Set-StrictMode -Version Latest

    if( Test-Path $Link -PathType Container )
    {
        $junction = Get-Item $Link
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
