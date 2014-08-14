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

function Find-OpenFile
{
    <#
    .SYNOPSIS
    Uses internal Windows APIs to find all open files and the process using each.

    .DESCRIPTION
    This function can take a few seconds, so be patient.

    It also uses internal Windows APIs to find them. So, you've been warned. There is no guarantee this function will work on new/different versions of Windows.

    .OUTPUTS
    Carbon.HandleInfo

    .EXAMPLE
    Find-OpenFile

    Demonstrates how to get a list of all the files that are currently open.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.HandleInfo])]
    param(
    )

    Set-StrictMode -Version 'Latest'

    [Carbon.HandleInfo]::GetFileSystemHandles()
}