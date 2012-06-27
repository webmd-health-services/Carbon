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

function New-Junction
{
    <#
    .SYNOPSIS
    Creates a new junction.
    
    .DESCRIPTION
    Creates a junction given by `-Link` which points to the path given by `-Target`.  If something already exists at `Link`, an error is written.  
    
    .EXAMPLE
    New-Junction -Link 'C:\Windows\system32Link' -Target 'C:\Windows\system32'
    
    Creates the `C:\Windows\system32Link` directory, which points to `C:\Windows\system32`.
    #>
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
        Write-Host "Creating junction $Link <=> $Target"
        [Carbon.IO.JunctionPoint]::Create( $Link, $Target, $false )
        if( Test-Path $Link -PathType Container ) 
        { 
            Get-Item $Link 
        } 
    }
}

function New-TempDir
{
    <#
    .SYNOPSIS
    Creates a new temporary directory with a random name.
    
    .DESCRIPTION
    A new temporary directory is created in the current users temporary directory.  The directory's name is created using the `Path` class's [GetRandomFileName method](http://msdn.microsoft.com/en-us/library/system.io.path.getrandomfilename.aspx).
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.io.path.getrandomfilename.aspx
    
    .EXAMPLE
    New-TempDir

    Returns the path to a temporary directory with a random name.    
    #>
    $tmpPath = [IO.Path]::GetTempPath()
    $newTmpDirName = [IO.Path]::GetRandomFileName()
    New-Item (Join-Path $tmpPath $newTmpDirName) -Type directory
}

function Remove-Junction
{
    <#
    .SYNOPSIS
    Removes a junction.
    
    .DESCRIPTION
    Safely removes a junction without removing the junction's target.  If you try to remove something that isn't a junction, an error will be written.  Use `Test-PathIsJunction` or the `IsJunction` extended method on `DirectoryInfo` object.
    
    .EXAMPLE
    Remove-Junction -Path 'C:\I\Am\A\Junction'
    
    Removes the `C:\I\Am\A\Junction`
    
    .LINK
    Test-PathIsJunction
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove.
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
    <#
    .SYNOPSIS
    Tests if a path is a junction.
    
    .DESCRIPTION
    Tests if path is the path to a junction.  If `Path` doesn't exist, returns false.
    
    The alternate way of doing this is to use the `IsJunction` extension method on `DirectoryInfo` objects, which are returned by the `Get-Item` and `Get-ChildItem` cmdlets.
    
    .EXAMPLE
    Test-PathIsJunction -Path C:\I\Am\A\Junction
    
    Returns `True`.
    
    .EXAMPLE
    Test-PathIsJunction -Path C:\I\Am\Not\A\Junction
    
    Returns `False`.
    
    .EXAMPLE
    Get-ChildItem * | Where-Object { $_.PsIsContainer -and $_.IsJunction }
    
    Demonstrates an alternative way of testing for junctions.  Uses Carbon's `IsJunction` extension method on the `DirectoryInfo` type to check if any directories under the current directory are junctions.
    #>
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

