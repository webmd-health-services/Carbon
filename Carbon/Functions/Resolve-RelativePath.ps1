
function Resolve-CRelativePath
{
    <#
    .SYNOPSIS
    Converts a path to a relative path from a given source.
    
    .DESCRIPTION
    The .NET framework doesn't expose an API for getting a relative path to an item.  This function uses Win32 APIs to call [PathRelativePathTo](http://msdn.microsoft.com/en-us/library/windows/desktop/bb773740.aspx).
    
    Neither the `From` or `To` paths need to exist.
    
    .EXAMPLE
    Resolve-CRelativePath -Path 'C:\Program Files' -FromDirectory 'C:\Windows\system32' 
    
    Returns `..\..\Program Files`.
    
    .EXAMPLE
    Get-ChildItem * | Resolve-CRelativePath -FromDirectory 'C:\Windows\system32'
    
    Returns the relative path from the `C:\Windows\system32` directory to the current directory.
    
    .EXAMPLE
    Resolve-CRelativePath -Path 'C:\I\do\not\exist\either' -FromDirectory 'C:\I\do\not\exist' 
    
    Returns `.\either`.
    
    .EXAMPLE
    Resolve-CRelativePath -Path 'C:\I\do\not\exist\either' -FromFile 'C:\I\do\not\exist_file' 
    
    Treats `C:\I\do\not\exist_file` as a file, so returns a relative path of `.\exist\either`.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb773740.aspx
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipelineByPropertyName=$true)]
        [string]
        # The path to convert to a relative path.  It will be relative to the value of the From parameter.
        [Alias('FullName')]
        $Path,
        
        [Parameter(Mandatory=$true,ParameterSetName='FromDirectory')]
        [string]
        # The source directory from which the relative path will be calculated.  Can be a string or an file system object.
        $FromDirectory,
        
        [Parameter(Mandatory=$true,ParameterSetName='FromFile')]
        [string]
        # The source directory from which the relative path will be calculated.  Can be a string or an file system object.
        $FromFile
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        $relativePath = New-Object System.Text.StringBuilder 260
        switch( $pscmdlet.ParameterSetName )
        {
            'FromFile'
            {
                $fromAttr = [IO.FileAttributes]::Normal
                $fromPath = $FromFile
            }
            'FromDirectory'
            {
                $fromAttr = [IO.FileAttributes]::Directory
                $fromPath = $FromDirectory
            }
        }
        
        $toPath = $Path
        if( $Path | Get-Member -Name 'FullName' )
        {
            $toPath = $Path.FullName
        }
        
        $toAttr = [IO.FileAttributes]::Normal
        $converted = [Carbon.IO.Path]::PathRelativePathTo( $relativePath, $fromPath, $fromAttr, $toPath, $toAttr )
        $result = if( $converted ) { $relativePath.ToString() } else { $null }
        return $result
    }
}
