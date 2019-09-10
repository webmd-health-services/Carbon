
function Test-CZipFile
{
    <#
    .SYNOPSIS
    Tests if a file is a ZIP file using the `DotNetZip` library.

    .DESCRIPTION
    Uses the `Ionic.Zip.ZipFile.IsZipFile` static method to determine if a file is a ZIP file.  The file *must* exist. If it doesn't, an error is written and `$null` is returned.

    You can pipe `System.IO.FileInfo` (or strings) to this function to filter multiple items.

    .LINK
    https://www.nuget.org/packages/DotNetZip

    .LINK
    Compress-CItem
    
    .LINK
    Expand-CItem
    
    .EXAMPLE
    Test-CZipFile -Path 'MyCoolZip.zip'
    
    Demonstrates how to check the current directory if MyCoolZip.zip is really a ZIP file.  
    #>
    [OutputType([bool])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Alias('FullName')]
        [string]
        # The path to the file to test.
        $Path
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Add-Type -Path (Join-Path -Path $CarbonBinDir -ChildPath 'Ionic.Zip.dll' -Resolve)

    $Path = Resolve-CFullPath -Path $Path
    if( -not (Test-Path -Path $Path -PathType Leaf) )
    {
        Write-Error ('File ''{0}'' not found.' -f $Path)
        return
    }

    return [Ionic.Zip.ZipFile]::IsZipFile( $Path )

}
