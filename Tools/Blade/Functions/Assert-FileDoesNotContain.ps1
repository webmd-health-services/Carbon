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

function Assert-FileDoesNotContain
{
    <#
    .SYNOPSIS
    Asserts that a file doesn not contain a string.

    .DESCRIPTION
    `Assert-FileDoesNotContain` searches a file for a string and fails if that string isf ound.

    .EXAMPLE
    Assert-FileDoesNotContain 'C:\Windows\System32\drivers\etc\hosts' '127.0.0.1'

    Demonstrates how to assert that a file does not contain a string.

    .EXAMPLE
    Assert-FileDoesNotContain 'C:\Windows\System32\drivers\etc\hosts' 'doubclick.net' 'Ad-blocking hosts entry not added.'

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
        # The string to not look for.
        $Needle,

        [Parameter(Position=2)]
        # A description about why the assertion might have failed.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Checking that '$Path' does not contain expected content."
    $actualContents = Get-Content -Path $Path -Raw
    Write-Debug -Message "Actual:`n$actualContents"
    Write-Debug -Message "Expected:`n$Needle"
    if( $actualContents -match ([Text.RegularExpressions.Regex]::Escape($Needle)) )
    {
        Fail ("File '{0}' contains '{1}'. {2}" -f $Path,$Needle,$Message)
    }
}

