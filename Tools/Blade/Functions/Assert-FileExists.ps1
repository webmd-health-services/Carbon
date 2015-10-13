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

function Assert-FileExists
{
    <#
    .SYNOPSIS
    Asserts that a file exists.

    .DESCRIPTION
    Uses PowerShell's `Test-Path` cmdlet to check if the file exists.

    .EXAMPLE
    Assert-FileExists 'C:\Windows\system32\drivers\etc\hosts'

    Demonstrates how to assert that a file exists.

    .EXAMPLE
    Assert-FileExists 'C:\foobar.txt' 'Foobar.txt wasn''t created.'

    Demonstrates how to describe why an assertion might fail.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        # The path to the file to check.
        $Path,

        [Parameter(Position=1)]
        [string]
        # A description of why the assertion might fail.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Testing if file '$Path' exists."
    if( -not (Test-Path $Path -PathType Leaf) )
    {
        Fail "File $Path does not exist. $Message"
    }
}

