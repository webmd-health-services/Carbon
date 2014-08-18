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
