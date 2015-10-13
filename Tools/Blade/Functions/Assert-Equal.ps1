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

function Assert-Equal
{
    <#
    .SYNOPSIS
    Asserts that two objects are equal.

    .DESCRIPTION
    Uses PowerShell's `-eq` operator to test if two objects are equal.  To perform a case-sensitive comparison with the `-ceq` operator, use the `-CaseSensitive` switch.

    .EXAMPLE
    Assert-Equal 'foo' 'FOO'

    Demonstrates that the equality is case-insensitive.

    .EXAMPLE
    Assert-Equal 'foo' 'FOO' -CaseSensitive

    Demonstrates that the equality is case-insensitive.

    .EXAMPLE
    Assert-Equal 'foo' 'bar' 'The bar didn''t foo!'

    Demonstrates how to include your own message when the assertion fails.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [object]
        # The expected value.
        $Expected, 

        [Parameter(Position=1)]
        [object]
        # The actual value.
        $Actual, 

        [Parameter(Position=2)]
        [string]
        # A message to show when the assertion fails.
        $Message,

        [Switch]
        # Performs a case-sensitive equality comparison.
        $CaseSensitive
    )

    Set-StrictMode -Version 'Latest'

    Write-Debug -Message "Is '$Expected' -eq '$Actual'?"
    $equal = $Expected -eq $Actual
    if( $CaseSensitive )
    {
        $equal = $Expected -ceq $Actual
    }

    if( -not $equal )
    {
        if( $Expected -is [string] -and $Actual -is [string] )
        {
            $expectedLength = $Expected.Length
            $actualLength = $Actual.Length

            function Convert-UnprintableChars
            {
                param(
                    [Parameter(Mandatory=$true,Position=0)]
                    [AllowEmptyString()]
                    [AllowNull()]
                    [string]
                    $InputObject
                )
                $InputObject = $InputObject -replace "`r","\r"
                $InputObject = $InputObject -replace "`n","\n`n"
                $InputObject = $InputObject -replace "`t","\t`t"
                return $InputObject
            }

            if( $expectedLength -ne $actualLength )
            {
                Fail ("Strings are different length ({0} != {1}).`n----- EXPECTED`n{2}`n----- ACTUAL`n{3}`n-----`n{4}" -f $expectedlength,$actualLength,(Convert-UnprintableChars $Expected),(Convert-UnprintableChars $Actual),$Message)
                return
            }

            for( $idx = 0; $idx -lt $Expected.Length; ++$idx )
            {
                $charEqual = $Expected[$idx] -eq $Actual[$idx]
                if( $CaseSensitive )
                {
                    $charEqual = $Expected[$idx] -ceq $Actual[$idx]
                }

                if( -not $charEqual )
                {
                    $startIdx = $idx - 70
                    if( $startIdx -lt 0 )
                    {
                        $startIdx = 0
                    }

                    $expectedSubstring = $Expected.Substring($startIdx,$idx - $startIdx + 1)
                    $actualSubstring = $Actual.Substring($startIdx,$idx - $startIdx + 1)
                    Fail ("Strings different beginning at index {0}:`n'{1}' != '{2}'`n----- EXPECTED`n{3}`n----- ACTUAL`n{4}`n-----`n{5}" -f $idx,(Convert-UnprintableChars $Expected[$idx]),(Convert-UnprintableChars $Actual[$idx]),(Convert-UnprintableChars $expectedSubstring),(Convert-UnprintableChars $actualSubstring),$Message)
                }
            }
            
        }
        Fail "Expected '$Expected', but was '$Actual'. $Message"
    }
}

