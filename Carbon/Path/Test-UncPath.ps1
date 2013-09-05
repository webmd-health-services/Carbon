
function Test-UncPath
{
    <#
    .SYNOPSIS
    Tests if a path is a UNC path.

    .DESCRIPTION
    Converts the path to a URI and returns the value of its `IsUnc` property.

    This function does not test if path exists.  Use `Test-Path` for that.

    .LINK
    Test-Path

    .LINK
    http://blogs.microsoft.co.il/blogs/ScriptFanatic//archive/2010/05/27/quicktip-how-to-validate-a-unc-path.aspx

    .EXAMPLE
    Test-UncPath -Path '\\computer\share'

    Returns `true` since `\\computer\share` is a UNC path.  Note that `Test-UncPath` does not have to exist.

    .EXAMPLE
    Test-UncPath -Path 'C:\Windows'

    Returns `false` since `C:\Windows` is not a UNC path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to test/check.
        $Path
    )

    ([Uri]$Path).IsUnc

}
