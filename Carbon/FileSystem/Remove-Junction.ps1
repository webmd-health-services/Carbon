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

function Remove-Junction
{
    <#
    .SYNOPSIS
    Removes a junction.
    
    .DESCRIPTION
    `Remove-Junction` removes an existing junction. You'll get errors if `Path` doesn't exist, is a file, or is a directory.
    
    .LINK
    Install-Junction

    .LINK
    New-Junction

    .LINK
    Uninstall-Junction

    .EXAMPLE
    Remove-Junction -Path 'C:\I\Am\A\Junction'
    
    Removes the `C:\I\Am\A\Junction`
    
    .LINK
    Test-PathIsJunction
    Uninstall-Junction
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    if( -not (Test-Path -Path $Path) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $Path)
        return
    }
    
    if( (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Error ('Path ''{0}'' is a file, not a junction.' -f $Path)
        return
    }
    
    if( Test-PathIsJunction $Path  )
    {
        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath
        if( $PSCmdlet.ShouldProcess($Path, "remove junction") )
        {
            [Carbon.IO.JunctionPoint]::Delete( $Path )
        }
    }
    else
    {
        Write-Error ("Path '{0}' is a directory, not a junction." -f $Path)
    }
}
