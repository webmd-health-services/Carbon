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
    `Remove-Junction` removes an existing junction. 
    
    In Carbon 2.1.1 and earlier, the `Path` paramater does not support wildcard characters, nor can it delete junctions that contained wildcards.

    Carbon 2.2.0 added support for wildcards in the `Path` parameter. If using wildcards, if the wildcard pattern doesn't match any junctions, nothing is removed and you'll get no errors. If the `Path` parameter does not contain wildcards, `Path` must exist and must be a path to a junction.

    Carbon 2.2.0 also added the `LiteralPath` parameter. Use it to delete junctions whose path contains wildcard characters.
    
    .LINK
    Install-Junction

    .LINK
    New-Junction

    .LINK
    Test-PathIsJunction

    .LINK
    Uninstall-Junction

    .EXAMPLE
    Remove-Junction -Path 'C:\I\Am\A\Junction'
    
    Removes the `C:\I\Am\A\Junction` path.

    .EXAMPLE
    Remove-Junction -path 'C:\Temp\*'

    Demonstrates how to use wildcards to delete multiple junctions in a directory. Nothing happens if the wildcard doesn't match any junctions.

    .EXAMPLE
    Remove-Junction -LiteralPath 'C:\Temp\ContainsWildcards[]'

    Demonstrates how to use the `Literalpath` parameter to delete a junction that contains wildcard characters.
    #>
    [CmdletBinding(SupportsShouldProcess=$true,DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,Position=0,ParameterSetName='Path')]
        [string]
        # The path to the junction to remove.
        #
        # Wildcards are supported in Carbon 2.2.0 and later.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        # The literal path to the junction to remove. Use this parameter to remove junctions whose paths contain wildcard characters.
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
            Get-Item -Path $Path |
                Where-Object { $_.PsIsContainer -and $_.IsJunction } |
                ForEach-Object { Remove-Junction -Path $_.FullName }
        }
        else
        {
            Remove-Junction -LiteralPath $Path
        }
        return
    }

    if( -not (Test-Path -LiteralPath $LiteralPath) )
    {
        Write-Error ('Path ''{0}'' not found.' -f $LiteralPath)
        return
    }
    
    if( (Test-Path -LiteralPath $LiteralPath -PathType Leaf) )
    {
        Write-Error ('Path ''{0}'' is a file, not a junction.' -f $LiteralPath)
        return
    }
    
    if( Test-PathIsJunction -LiteralPath $LiteralPath  )
    {
        $LiteralPath = Resolve-Path -LiteralPath $LiteralPath | 
                            Select-Object -ExpandProperty ProviderPath
        if( $PSCmdlet.ShouldProcess($LiteralPath, "remove junction") )
        {
            [Carbon.IO.JunctionPoint]::Delete( $LiteralPath )
        }
    }
    else
    {
        Write-Error ("Path '{0}' is a directory, not a junction." -f $LiteralPath)
    }
}

