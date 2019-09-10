
function Install-CJunction
{
    <#
    .SYNOPSIS
    Creates a junction, or updates an existing junction if its target is different.
    
    .DESCRIPTION
    Creates a junction given by `-Link` which points to the path given by `-Target`.  If `Link` exists, deletes it and re-creates it if it doesn't point to `Target`.
    
    Both `-Link` and `-Target` parameters accept relative paths for values.  Any non-rooted paths are converted to full paths using the current location, i.e. the path returned by `Get-Location`.

    Beginning with Carbon 2.0, returns a `System.IO.DirectoryInfo` object for the target path, if one is created.  Returns a `System.IO.DirectoryInfo` object for the junction, if it is created and/or updated.

    .OUTPUTS
    System.IO.DirectoryInfo. To return a `DirectoryInfo` object for installed junction, use the `PassThru` switch.
    
    .LINK
    New-CJunction

    .LINK
    Remove-CJunction

    .EXAMPLE
    Install-CJunction -Link 'C:\Windows\system32Link' -Target 'C:\Windows\system32'
    
    Creates the `C:\Windows\system32Link` directory, which points to `C:\Windows\system32`.

    .EXAMPLE
    Install-CJunction -Link C:\Projects\Foobar -Target 'C:\Foo\bar' -Force

    This example demonstrates how to create the target directory if it doesn't exist.  After this example runs, the directory `C:\Foo\bar` and junction `C:\Projects\Foobar` will be created.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([IO.DirectoryInfo])]
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The junction to create/update. Relative paths are converted to absolute paths using the current location.
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to.  Relative paths are converted to absolute paths using the curent location.
        $Target,

        [Switch]
        # Return a `DirectoryInfo` object for the installed junction. Returns nothing if `WhatIf` switch is used. This switch is new in Carbon 2.0.
        $PassThru,

        [Switch]
        # Create the target directory if it does not exist.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $Link = Resolve-CFullPath -Path $Link
    $Target = Resolve-CFullPath -Path $Target

    if( Test-Path -LiteralPath $Target -PathType Leaf )
    {
        Write-Error ('Unable to create junction {0}: target {1} exists and is a file.' -f $Link,$Target)
        return
    }

    if( -not (Test-Path -LiteralPath $Target -PathType Container) )
    {
        if( $Force )
        {
            New-Item -Path $Target -ItemType Directory -Force | Out-String | Write-Verbose
        }
        else
        {
            Write-Error ('Unable to create junction {0}: target {1} not found.  Use the `-Force` switch to create target paths that don''t exist.' -f $Link,$Target)
            return
        }
    }

    if( Test-Path -LiteralPath $Link -PathType Container )
    {
        $junction = Get-Item -LiteralPath $Link -Force
        if( -not $junction.IsJunction )
        {
            Write-Error ('Failed to create junction ''{0}'': a directory exists with that path and it is not a junction.' -f $Link)
            return
        }

        if( $junction.TargetPath -eq $Target )
        {
            return
        }

        Remove-CJunction -LiteralPath $Link
    }

    if( $PSCmdlet.ShouldProcess( $Target, ("creating '{0}' junction" -f $Link) ) )
    {
        $result = New-CJunction -Link $Link -Target $target -Verbose:$false
        if( $PassThru )
        {
            return $result
        }
    }
}

