
function Assert-WhiskeyNodePath
{
    <#
    .SYNOPSIS
    Asserts that the path to a node executable exists.

    .DESCRIPTION
    The `Assert-WhiskeyNodePath` function asserts that a path to a Node executable exists. If it doesn't, it writes an error with details on how to solve the problem. It returns the path if it exists. Otherwise, it returns nothing.

    This won't fail a build. To fail a build if the path doesn't exist, pass `-ErrorAction Stop`.

    .EXAMPLE
    Assert-WhiskeyNodePath -Path $TaskParameter['NodePath']

    Demonstrates how to check that Node exists.

    .EXAMPLE
    Assert-WhiskeyNodePath -Path $TaskParameter['NodePath'] -ErrorAction Stop

    Demonstrates how to fail a build if the path to Node doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to check.
        $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Error -Message ('Node executable ''{0}'' does not exist. Whiskey maybe failed to install Node correctly. Clean your build then re-run your build normally. If the problem persists, it might be a task authoring error. Please see the `about_Whiskey_Writing_Tasks` help topic for more information.' -f $Path)        
        return
    }

    return $Path
}