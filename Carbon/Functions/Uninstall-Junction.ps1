
function Uninstall-CJunction
{
    <#
    .SYNOPSIS
    Uninstall a junction.
    
    .DESCRIPTION
    The `Uninstall-CJunction` removes a junction that may or may not exist. If the junction exists, it is removed. If a junction doesn't exist, nothing happens.
    
    If the path to uninstall is not a direcory, you *will* see errors.

    `Uninstall-CJunction` is new in Carbon 2.0.

    Beginning in Carbon 2.2.0, you can uninstall junctions whose paths contain wildcard characters with the `LiteralPath` parameter.
    
    .LINK
    Install-CJunction

    .LINK
    New-CJunction

    .LINK
    Remove-CJunction

    .EXAMPLE
    Uninstall-CJunction -Path 'C:\I\Am\A\Junction'
    
    Uninstall the `C:\I\Am\A\Junction`
    
    .LINK
    Test-CPathIsJunction
    Remove-CJunction
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
            Remove-CJunction -Path $Path
            return
        }

        $LiteralPath = $Path
    }

    if( (Test-Path -LiteralPath $LiteralPath) )
    {
        Remove-CJunction -LiteralPath $LiteralPath
    }
}

