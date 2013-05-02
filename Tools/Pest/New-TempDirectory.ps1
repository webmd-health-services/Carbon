
function New-TempDirectory
{
    <#
    .SYNOPSIS
    Creates a new temporary directory.
    #>
    param(
        [string]
        # An optional prefix for the temporary directory name.  Helps in identifying tests and things that don't properly clean up after themselves.1
        $Prefix
    )
    
    $tmpPath = [System.IO.Path]::GetTempPath()
    $newTmpDirName = [System.IO.Path]::GetRandomFileName()
    if( $Prefix )
    {
        $newTmpDirName = '{0}-{1}' -f $Prefix,$newTmpDirName
    }
    
    New-Item (Join-Path $tmpPath $newTmpDirName) -Type Directory
}


Set-Alias -Name 'New-TempDir' -Value 'New-TempDirectory'
