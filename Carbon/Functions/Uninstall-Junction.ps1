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

function Uninstall-Junction
{
    <#
    .SYNOPSIS
    Uninstall a junction.
    
    .DESCRIPTION
    `Uninstall-Junction` removes a junction that may or may not exist, without errors.
    
    If `Path` is not a direcory, you *will* see errors.

    `Uninstall-Junction` is new in Carbon 2.0.
    
    .LINK
    Install-Junction

    .LINK
    New-Junction

    .LINK
    Remove-Junction

    .EXAMPLE
    Uninstall-Junction -Path 'C:\I\Am\A\Junction'
    
    Uninstall the `C:\I\Am\A\Junction`
    
    .LINK
    Test-PathIsJunction
    Remove-Junction
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove.
        $Path
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-Path -Path $Path) )
    {
        return
    }

    Remove-Junction -Path $Path
}
