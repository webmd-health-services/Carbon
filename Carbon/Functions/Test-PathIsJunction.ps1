
function Test-CPathIsJunction
{
    <#
    .SYNOPSIS
    Tests if a path is a junction.
    
    .DESCRIPTION
    The `Test-CPathIsJunction` function tests if path is a junction (i.e. reparse point). If the path doesn't exist, returns `$false`.
    
    Carbon adds an `IsJunction` extension method on `DirectoryInfo` objects, which you can use instead e.g.
    
        Get-ChildItem -Path $env:Temp | 
            Where-Object { $_.PsIsContainer -and $_.IsJunction }

    would return all the junctions under the current user's temporary directory.

    The `LiteralPath` parameter was added in Carbon 2.2.0. Use it to check paths that contain wildcard characters.
    
    .EXAMPLE
    Test-CPathIsJunction -Path C:\I\Am\A\Junction
    
    Returns `$true`.
    
    .EXAMPLE
    Test-CPathIsJunction -Path C:\I\Am\Not\A\Junction
    
    Returns `$false`.
    
    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer -and $_.IsJunction }
    
    Demonstrates an alternative way of testing for junctions.  Uses Carbon's `IsJunction` extension method on the `DirectoryInfo` type to check if any directories under the current directory are junctions.

    .EXAMPLE
    Test-CPathIsJunction -LiteralPath 'C:\PathWithWildcards[]'

    Demonstrates how to test if a path with wildcards is a junction.
    #>
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Path',Position=0)]
        [string]
        # The path to check. Wildcards allowed. If using wildcards, returns `$true` if all paths that match the wildcard are junctions. Otherwise, return `$false`.
        $Path,

        [Parameter(Mandatory=$true,ParameterSetName='LiteralPath')]
        [string]
        # The literal path to check. Use this parameter to test a path that contains wildcard characters.
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
            $junctions = Get-Item -Path $Path -Force |
                            Where-Object { $_.PsIsContainer -and $_.IsJunction }
            
            return ($junctions -ne $null)        
        }

        return Test-CPathIsJunction -LiteralPath $Path
    }

    if( Test-Path -LiteralPath $LiteralPath -PathType Container )
    {
        return (Get-Item -LiteralPath $LiteralPath -Force).IsJunction
    }

    return $false
}

