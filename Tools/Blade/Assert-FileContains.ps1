# Copyright 2012 - 2014 Aaron Jensen
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

function Assert-FileContains
{
    <#
    .SYNOPSIS
    Asserts that a file contains another string.

    .DESCRIPTION
    Performs a case-sensitive check for the string within the file.  

    .EXAMPLE
    Assert-FileContains 'C:\Windows\System32\drivers\etc\hosts' '127.0.0.1'

    Demonstrates how to assert that a file contains a string.

    .EXAMPLE
    Assert-FileContains 'C:\Windows\System32\drivers\etc\hosts' 'doubclick.net' 'Ad-blocking hosts entry not added.

    Shows how to use the `Message` parameter to describe why the assertion might fail.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]
        # The path to the file.
        $Path,

        [Parameter(Position=1)]
        [string]
        # The string to look for. Case-sensitive.
        $Needle,

        [Parameter(Position=2)]
        # A description about why the assertion might have failed.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Verbose "Checking if '$Path' contains expected content."
    $actualContents = Get-Content -Path $Path -Raw
    Write-Verbose "Actual:`n$actualContents"
    Write-Verbose "Expected:`n$Needle"
    if( $actualContents.Contains($Needle) )
    {
        Fail ("File '{0}' does not contain '{1}'. {2}" -f $Path,$Needle,$Message)
    }
}

