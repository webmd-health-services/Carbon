# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function ConvertTo-FullPath
{
    <#
    .SYNOPSIS
    Converts a relative path to an absolute path.
    
    .DESCRIPTION
    Unlike `Resolve-Path`, this function does not check whether the path exists.  It just converts relative paths to absolute paths.
    
    You can't pass truly relative paths to this function.  You can only pass rooted paths, i.e. the path must have a drive at the beginning.
    
    .EXAMPLE
    ConvertTo-FullPath -Path 'C:\Projects\Carbon\Test\..\Carbon\FileSystem.ps1'
    
    Returns `C:\Projects\Carbon\Carbon\FileSystem.ps1`.
    
    .EXAMPLE
    ConvertTo-FullPath -Path 'C:\Projects\Carbon\..\I\Do\Not\Exist'
    
    Returns `C:\Projects\I\Do\Not\Exist`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to resolve.  Must be rooted, i.e. have a drive at the beginning.
        $Path
    )
    
    if( -not ( [System.IO.Path]::IsPathRooted($Path) ) )
    {
        Write-Warning "Path to resolve is not rooted. Path.GetFullPath uses Environment.CurrentDirectory as the path root, which isn't set to PowerShell's current directory."
    }
    return [IO.Path]::GetFullPath($Path)
}

function Get-PathCanonicalCase
{
    <#
    .SYNOPSIS
    Returns the real, canonical case of a path.
    
    .DESCRIPTION
    The .NET and Windows path/file system APIs respect and preserve the case of paths passed to them.  This function will return the actual case of a path on the file system, regardless of the case of the string passed in.
    
    If the path doesn't an exist, an error is written and nothing is returned.
    
    .EXAMPLE
    Get-PathCanonicalCase -Path "C:\WINDOWS\SYSTEM32"
    
    Returns `C:\Windows\system32`.
    
    .EXAMPLE
    Get-PathCanonicalCase -Path 'c:\projects\carbon' 
    
    Returns `C:\Projects\Carbon`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path whose real, canonical case should be returned.
        $Path
    )
    
    if( -not (Test-Path $Path) )
    {
        Write-Error "Path '$Path' doesn't exist."
        return
    }
    
    $shortBuffer = New-Object Text.StringBuilder ($Path.Length * 2)
    [void] [Carbon.Win32]::GetShortPathName( $Path, $shortBuffer, $shortBuffer.Capacity )
    
    $longBuffer = New-Object Text.StringBuilder ($Path.Length * 2)
    [void] [Carbon.Win32]::GetLongPathName( $shortBuffer.ToString(), $longBuffer, $longBuffer.Capacity )
    
    return $longBuffer.ToString()
}

function Resolve-RelativePath
{
    <#
    .SYNOPSIS
    Converts a path to a relative path from a given source.
    
    .DESCRIPTION
    The .NET framework doesn't expose an API for getting a relative path to an item.  This function uses Win32 APIs to call [PathRelativePathTo](http://msdn.microsoft.com/en-us/library/windows/desktop/bb773740.aspx).
    
    Neither the `From` or `To` paths need to exist.
    
    .EXAMPLE
    Resolve-RelativePath -Path 'C:\Program Files' -FromDirectory 'C:\Windows\system32' 
    
    Returns `..\..\Program Files`.
    
    .EXAMPLE
    Get-ChildItem * | Resolve-RelativePath -FromDirectory 'C:\Windows\system32'
    
    Returns the relative path from the `C:\Windows\system32` directory to the current directory.
    
    .EXAMPLE
    Resolve-RelativePath -Path 'C:\I\do\not\exist\either' -FromDirectory 'C:\I\do\not\exist' 
    
    Returns `.\either`.
    
    .EXAMPLE
    Resolve-RelativePath -Path 'C:\I\do\not\exist\either' -FromFile 'C:\I\do\not\exist_file' 
    
    Treats `C:\I\do\not\exist_file` as a file, so returns a relative path of `.\exist\either`.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/bb773740.aspx
    #>
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
    
    process
    {
        $relativePath = New-Object System.Text.StringBuilder 260
        switch( $pscmdlet.ParameterSetName )
        {
            'FromFile'
            {
                $fromAttr = [System.IO.FileAttributes]::Normal
                $fromPath = $FromFile
            }
            'FromDirectory'
            {
                $fromAttr = [System.IO.FileAttributes]::Directory
                $fromPath = $FromDirectory
            }
        }
        
        $toPath = $Path
        if( $Path.FullName )
        {
            $toPath = $Path.FullName
        }
        
        $toAttr = [System.IO.FileAttributes]::Normal
        $converted = [Carbon.Win32]::PathRelativePathTo( $relativePath, $fromPath, $fromAttr, $toPath, $toAttr )
        $result = if( $converted ) { $relativePath.ToString() } else { $null }
        return $result
    }
}