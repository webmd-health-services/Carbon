
function Assert-WhiskeyNodeModulePath
{
    <#
    .SYNOPSIS
    Asserts that the path to a Node module directory exists.

    .DESCRIPTION
    The `Assert-WhiskeyNodeModulePath` function asserts that a Node module directory exists. If the directory doesn't exist, the function writes an error with details on how to solve the problem. It returns the path if it exists. Otherwise, it returns nothing.

    This won't fail a build. To fail a build if the path doesn't exist, pass `-ErrorAction Stop`.

    .EXAMPLE
    Assert-WhiskeyNodeModulePath -Path $TaskParameter['NspPath']

    Demonstrates how to check that a Node module directory exists.

    .EXAMPLE
    Assert-WhiskeyNodeModulePath -Path $TaskParameter['NspPath'] -ErrorAction Stop

    Demonstrates how to fail a build if a Node module directory doesn't exist.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to check.
        $Path,

        [string]
        # The path to a command inside the module path.
        $CommandPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $moduleName = $Path | Split-Path
    
    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        Write-Error -Message ('Node module ''{0}'' does not exist at ''{1}''. Whiskey or NPM maybe failed to install this module correctly. Clean your build then re-run your build normally. If the problem persists, it might be a task authoring error. Please see the `about_Whiskey_Writing_Tasks` help topic for more information.' -f $moduleName,$Path)        
        return
    }

    if( -not $CommandPath )
    {
        return $Path
    }

    $commandName = $CommandPath | Split-Path -Leaf

    $fullCommandPath = Join-Path -Path $Path -ChildPath $CommandPath
    if( -not (Test-Path -Path $fullCommandPath -PathType Leaf) )
    {
        Write-Error -Message ('Node module ''{0}'' does not contain command ''{1}'' at ''{2}''. Whiskey or NPM maybe failed to install this module correctly or that command doesn''t exist in this version of the module. Clean your build then re-run your build normally. If the problem persists, it might be a task authoring error. Please see the `about_Whiskey_Writing_Tasks` help topic for more information.' -f $moduleName,$commandName,$fullCommandPath)
        return
    }

    return $fullCommandPath
}