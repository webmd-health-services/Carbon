# Copyright 2012 - 2015 Aaron Jensen
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

function New-TempDirectoryTree
{
    <#
    .SYNOPSIS
    Creates a directory tree using a custom DSL.

    .DESCRIPTION
    Use this function to setup a quick directory/file structure in the current temporary directory for a test using a concise DSL.  The directory structure is specified in a string.  Each item for the directory tree should be on its own line.  Directory names should be prefixed with `+`.  Files should be prefixed with `*`.  Items that should be within a parent directory should be indented two spaces from the position of its parent.  A quick example will probably show it better:

        + RootDir
          * ChildFile.txt
          + ChildDir
            * GrandchildFile.txt
            * GrandchildFile2.txt
        * RootFile.txt

    Easy! A `System.IO.DirectoryInfo` object is returned for the directory which contains your new directory/file tree.

    .OUTPUTS
    System.IO.DirectoryInfo.

    .EXAMPLE
    New-TempDirectoryTree -Tree "+ RootDir`n*RootFile.txt"

    Creates the following directory tree in its own directory under the current user's temporary directory:

        + RootDir
        * RootFile.txt

    The directory name is randomly generated.

    .EXAMPLE
    New-TempDirectoryTree -Tree "* File1`n* File2" -Prefix 'Test-FilesSkipped'

    Creates the following directory tree in its own directory under the current user's temporary directory:

        * File1
        * File2

    The directory name (randomly generated) is prefixed with `Test-FilesSkipped`, e.g `Test-FilesSkipped53q5rekv.kab'

    .EXAMPLE
    New-TempDirectoryTree -Tree "+ Dir1`n  + Dir 2`n    + Dir3" -Path 'C:\Projects\Blade\Test\Test-TempDirectoryTree'

    Creates the following directories in the `C:\Projects\Blade\Test\Test-TempDirectoryTree` directory:

        + Dir1
          + Dir2
            + Dir3

    If `Path` doesn't exist, it is created.
    #>
    [CmdletBinding(DefaultParameterSetName='TempPath')]
    param(
        [Parameter(Mandatory=$true,Position=1)]
        [AllowEmptyString()]
        [string]
        # The directory tree to create.
        $Tree,
        
        [Parameter(ParameterSetName='TempPath')]
        [string]
        # An optional prefix for the temporary directory's name.
        $Prefix,

        [Parameter(Mandatory=$true,ParameterSetName='ExistingPath')]
        [string]
        # The path where the directory tree should be created.  Defaults to a new directory in the `$env:TEMP` directory.
        $Path
    )
    
    $stackName = 'New-TempDirectoryTree'
    
    if( $PSCmdlet.ParameterSetName -eq 'TempPath' )
    {
        $optionalParams = @{ }
        if( $Prefix )
        {
            $optionalParams.Prefix = $Prefix
        }
    
        $tempDir = New-TempDirectory @optionalParams
    }
    else
    {
        if( (Test-Path -Path $Path -PathType Container) )
        {
            $tempDir = Get-Item -Path $Path
        }
        else
        {
            $tempDir = New-Item -Path $Path -ItemType Directory -Force
        }
    }
    $startLocation = Get-Location
    Push-Location -Path $tempDir -StackName $stackName
    
    try
    {
        $parent = $tempDir
        $lastDir = $tempDir
        $lastIndent = ''
        
        ($Tree -split "`r?`n") |
            Where-Object { $_ } |
            ForEach-Object {
                if( $_ -notmatch '^((  )+)?(\*|\+) ?(.*)$' )
                {
                    Write-Error ('Invalid line for directory tree: <{0}>' -f $_)
                    return
                }
                $indent = $matches[1]
                if( -not $indent )
                {
                    $indent = ''
                }
                
                $itemType = $matches[3]
                $name = $matches[4]
                
                if( $lastIndent.Length -lt $indent.Length )
                {
                    Push-Location -Path (Join-Path (Get-Location) $lastDir) -StackName $stackName
                }
                elseif( $indent.Length -lt $lastIndent.Length )
                {
                    $levelsUp = (($lastIndent.Length - $indent.Length) / 2) - 1
                    (0..$levelsUp) | ForEach-Object { Pop-Location -StackName $stackName }
                }
                else
                {
                    # Same level.  Do nothing.
                }
                
                if( $itemType -eq '*' )
                {
                    $itemType = 'File'
                    $pathType = 'Leaf'
                }
                else
                {
                    $itemType = 'Directory'
                    $pathType = 'Container'
                    $lastDir = $name
                }
                
                if( -not (Test-Path -Path $name -PathType $pathType) )
                {
                    $null = New-Item -Path $name -ItemType $itemType
                }
                
                $lastIndent = $indent
            }
            
        $tempDir
    }
    finally
    {
        Set-Location $startLocation
    }
}

