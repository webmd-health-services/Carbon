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

function Get-FullPath($relativePath)
{
    if( -not ( [System.IO.Path]::IsPathRooted($relativePath) ) )
    {
        Write-Warning "Path to resolve is not rooted.  Please pass a rooted path to Get-FullPath.  Path.GetFullPath uses Environment.CurrentDirectory as the path root, which PowerShell doesn't update."
    }
    return [System.IO.Path]::GetFullPath($relativePath)
}

function Get-PathCanonicalCase
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # Gets the real case of a path
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

function Get-PathRelativeTo
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $From,
        
        [Parameter(Position=1)]
        [ValidateSet('Directory', 'File')]
        $FromType = 'Directory',
        
        [Parameter(ValueFromPipeline=$true)]
        $To
    )
    
    process
    {
        $relativePath = New-Object System.Text.StringBuilder 260
        $fromAttr = [System.IO.FileAttributes]::Directory
        if( $FromType -eq 'File' )
        {
            $fromAttr = [System.IO.FileAttributes]::Normal
        }
        
        $toPath = $To
        if( $To.FullName )
        {
            $toPath = $To.FullName
        }
        
        $toAttr = [System.IO.FileAttributes]::Normal
        $converted = [Carbon.Win32]::PathRelativePathTo( $relativePath, $From, $fromAttr, $toPath, $toAttr )
        $result = if( $converted ) { $relativePath.ToString() } else { $null }
        return $result
    }
}

function New-Junction
{
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The new junction to create
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to
        $Target
    )
    
    if( Test-Path $Link -PathType Container )
    {
        Write-Error "'$Link' already exists."
    }
    else
    {
        [Carbon.IO.JunctionPoint]::Create( $Link, $Target, $false )
        if( Test-Path $Link -PathType Container ) 
        { 
            Get-Item $Link 
        } 
    }
}

function New-TempDir
{
    $tmpPath = [System.IO.Path]::GetTempPath()
    $newTmpDirName = [System.IO.Path]::GetRandomFileName()
    New-Item (Join-Path $tmpPath $newTmpDirName) -Type directory
}

function Remove-Junction
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove
        $Path
    )
    
    if( Test-PathIsJunction $Path  )
    {
        if( $pscmdlet.ShouldProcess($Path, "remove junction") )
        {
            Write-Host "Removing junction $Path."
            [Carbon.IO.JunctionPoint]::Delete( $Path )
        }
    }
    else
    {
        Write-Error "'$Path' doesn't exist or is not a junction."
    }
}

function Test-PathIsJunction
{
    param(
        [string]
        # The path to check
        $Path
    )
    
    if( Test-Path $Path -PathType Container )
    {
        return (Get-Item $Path).IsJunction
    }
    return $false
}

