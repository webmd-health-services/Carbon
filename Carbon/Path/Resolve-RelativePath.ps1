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