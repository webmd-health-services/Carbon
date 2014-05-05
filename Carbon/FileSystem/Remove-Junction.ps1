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
    Safely removes a junction without removing the junction's target.  If you try to remove something that isn't a junction, an error will be written.  Use `Test-PathIsJunction` or the `IsJunction` extended method on `DirectoryInfo` object.
    
    .LINK
    Install-Junction

    .LINK
    New-Junction

    .EXAMPLE
    Remove-Junction -Path 'C:\I\Am\A\Junction'
    
    Removes the `C:\I\Am\A\Junction`
    
    .LINK
    Test-PathIsJunction
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove.
        $Path
    )

    Set-StrictMode -Version 'Latest'
    
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
        Write-Error "'$Path' doesn't exist or is not a junction."
    }
}
