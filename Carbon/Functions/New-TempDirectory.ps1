
function New-CTempDirectory
{
    <#
    .SYNOPSIS
    Creates a new temporary directory with a random name.
    
    .DESCRIPTION
    A new temporary directory is created in the current user's `env:TEMP` directory.  The directory's name is created using the `Path` class's [GetRandomFileName method](http://msdn.microsoft.com/en-us/library/system.io.path.getrandomfilename.aspx).

    To add a custom prefix to the directory name, use the `Prefix` parameter. If you pass in a path, only its name will be used. In this way, you can pass `$MyInvocation.MyCommand.Definition` (PowerShell 2) or `$PSCommandPath` (PowerShell 3+), which will help you identify what scripts are leaving cruft around in the temp directory.

    Added `-WhatIf` support in Carbon 2.0.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.io.path.getrandomfilename.aspx
    
    .EXAMPLE
    New-CTempDirectory

    Demonstrates how to create a new temporary directory, e.g. `C:\Users\ajensen\AppData\Local\Temp\5pobd3tu.5rn`.

    .EXAMPLE
    New-CTempDirectory -Prefix 'Carbon'

    Demonstrates how to create a new temporary directory with a custom prefix for its name, e.g. `C:\Users\ajensen\AppData\Local\Temp\Carbon5pobd3tu.5rn`.

    .EXAMPLE
    New-CTempDirectory -Prefix $MyInvocation.MyCommand.Definition

    Demonstrates how you can use `$MyInvocation.MyCommand.Definition` in PowerShell 2 to create a new, temporary directory, named after the currently executing scripts, e.g. `C:\Users\ajensen\AppData\Local\Temp\New-CTempDirectory.ps15pobd3tu.5rn`. 

    .EXAMPLE
    New-CTempDirectory -Prefix $PSCommandPath

    Demonstrates how you can use `$PSCommandPath` in PowerShell 3+ to create a new, temporary directory, named after the currently executing scripts, e.g. `C:\Users\ajensen\AppData\Local\Temp\New-CTempDirectory.ps15pobd3tu.5rn`. 
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([IO.DirectoryInfo])]
    param(
        [string]
        # A prefix to use, so you can more easily identify *what* created the temporary directory. If you pass in a path, it will be converted to a file name.
        $Prefix
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $tempDir = [IO.Path]::GetRandomFileName()
    if( $Prefix )
    {
        $Prefix = Split-Path -Leaf -Path $Prefix
        $tempDir = '{0}{1}' -f $Prefix,$tempDir
    }

    $tempDir = Join-Path -Path $env:TEMP -ChildPath $tempDir
    New-Item -Path $tempDir -ItemType 'Directory' -Verbose:$VerbosePreference
}

Set-Alias -Name 'New-TempDir' -Value 'New-CTempDirectory'
