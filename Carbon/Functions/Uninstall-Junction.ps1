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
    The `Uninstall-Junction` removes a junction that may or may not exist. If the junction exists, it is removed. If a junction doesn't exist, nothing happens.
    
    If the path to uninstall is not a direcory, you *will* see errors.

    `Uninstall-Junction` is new in Carbon 2.0.

    Beginning in Carbon 2.2.0, you can uninstall junctions whose paths contain wildcard characters with the `LiteralPath` parameter.
    
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
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='Path')]
        [string]
        # The path to the junction to remove. Wildcards supported.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        # The literal path to the junction to remove. Use this parameter if the junction's path contains wildcard characters.
        #
        # This parameter was added in Carbon 2.2.0.
        $LiteralPath
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'Path' )
    {
        if( [Management.Automation.WildcardPattern]::ContainsWildcardCharacters($Path) )
        {
            Remove-Junction -Path $Path
            return
        }

        $LiteralPath = $Path
    }

    if( (Test-Path -LiteralPath $LiteralPath) )
    {
        Remove-Junction -LiteralPath $LiteralPath
    }
}

