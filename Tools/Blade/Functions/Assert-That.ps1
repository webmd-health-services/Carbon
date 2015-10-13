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

function Assert-That
{
    <#
    .SYNOPSIS
    Asserts that an object meets certain conditions and throws an exception when they aren't.

    .DESCRIPTION
    The `Assert-That` function checks that a given set of condiions are true and if they aren't, it throws a `Blade.AssertionException`.

    .EXAMPLE
    Assert-That { throw 'Fubar!' } -Throws [Management.Automation.RuntimeException]

    Demonstrates how to check that a script block throws an exception.
    
    .EXAMPLE
    Assert-That { } -DoesNotThrowException
    
    Demonstrates how to check that a script block doesn't throw an exception.

    .EXAMPLE
    Assert-That @( 1, 2, 3 ) -Contains 2

    Demonstrates how to check if an array, list, or other collection contains an object.

    .EXAMPLE
    Assert-That @{ 'fubar' = 'snafu' } -Contains 'fubar'

    Demonstrates how to check if a hashtable/dictionary object contains a value.

    .EXAMPLE
    Assert-That 'fubar' -Contains 'UBA'

    Demonstrates how to check if a string contains a substring. The search is case-insensitive.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [object]
        # The object whose conditions you're checking.
        $InputObject,

        [Parameter(Mandatory=$true,ParameterSetName='Contains')]
        [object]
        # Asserts that `InputObject` contains a value. `InputObject` can be an array, list, hashtable, dictionary, collection or a single string. If `InputObject` is another type, it is first converted to a string before being searched.
        #
        # If `InputObject` is an array or list, this function uses PowerShell's `-contains` operator to determine if it contains `Contains`, e.g. `$InputObject -contains $Contains`.
        #
        # If `InputObject` is a dictionary, this function uses its `Contains` method to determine if it contains `Contains`, e.g. `$InputObject.Contains($Contains)`.
        #
        # If `InputObject` is a collection, this function enumerates through each item in the collection and uses PowerShell's `-eq` operator to determine if it matches/is equal to `Contains` e.g.
        #
        #     foreach( $item in $InputObject.GetEnumerator() )
        #     {
        #         if( $item -eq $Contains )
        #         {
        #         }
        #     }
        #
        # In all other cases, `InputObject` and `Contains` are converted to strings and compared using the `-like` operator. Any wildcards in `Contains` are escaped and it is wrapped in the `*` wildcard, e.g. `$InputObject -like ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($Contains))`.
        $Contains,

        [Parameter(Mandatory=$true,ParameterSetName='DoesNotContain')]
        [object]
        # Asserts that `InputObject` does not contain a value. `InputObject` can be an array, list, hashtable, dictionary, collection or a single string. If `InputObject` is another type, it is first converted to a string before being searched.
        #
        # If `InputObject` is an array or list, this function uses PowerShell's `-contains` operator to determine if it contains `Contains`, e.g. `$InputObject -contains $Contains`.
        #
        # If `InputObject` is a dictionary, this function uses its `Contains` method to determine if it contains `Contains`, e.g. `$InputObject.Contains($Contains)`.
        #
        # If `InputObject` is a collection, this function enumerates through each item in the collection and uses PowerShell's `-eq` operator to determine if it matches/is equal to `Contains` e.g.
        #
        #     foreach( $item in $InputObject.GetEnumerator() )
        #     {
        #         if( $item -eq $Contains )
        #         {
        #         }
        #     }
        #
        # In all other cases, `InputObject` and `Contains` are converted to strings and compared using the `-like` operator. Any wildcards in `Contains` are escaped and it is wrapped in the `*` wildcard, e.g. `$InputObject -like ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($Contains))`.
        $DoesNotContain,

        [Parameter(Mandatory=$true,ParameterSetName='DoesNotThrowException')]
        [Switch]
        # Asserts that the script block given by `InputObject` does not throw an exception.
        $DoesNotThrowException,

        [Parameter(Mandatory=$true,ParameterSetName='ThrowsException')]
        [Type]
        # The type of the exception `$InputObject` should throw. When this parameter is provided, $INputObject should be a script block.
        $Throws,

        [Parameter(ParameterSetName='ThrowsException')]
        [string]
        # Used with the `Throws` switch. Checks that the thrown exception message matches a regular rexpression.
        $AndMessageMatches,

        [Parameter(ParameterSetName='Contains',Position=1)]
        [Parameter(ParameterSetName='DoesNotContain',Position=1)]
        [Parameter(ParameterSetName='ThrowsException',Position=1)]
        [string]
        # The message to show when the assertion fails.
        $Message
    )

    Set-StrictMode -Version 'Latest'

    switch( $PSCmdlet.ParameterSetName )
    {
        'Contains'
        {
            $interfaces = $InputObject.GetType().GetInterfaces()
            $failureMessage = @'
----------------------------------------------------------------------
{0}
----------------------------------------------------------------------

does not contain

----------------------------------------------------------------------
{1}
----------------------------------------------------------------------

{2}
'@ -f $InputObject,$Contains,$Message

            if( ($interfaces | Where-Object { $_.Name -eq 'IList' } ) )
            {
                if( $InputObject -notcontains $Contains )
                {
                    Fail $failureMessage
                    return
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'IDictionary' }) )
            {
                if( -not $InputObject.Contains( $Contains ) )
                {
                    Fail $failureMessage
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'ICollection' } ) )
            {
                $found = $false
                foreach( $item in $InputObject.GetEnumerator() )
                {
                    if( $item -eq $Contains )
                    {
                        $found = $true
                        break
                    }
                }

                if( -not $found )
                {
                    Fail $failureMessage
                }
            }
            else
            {
                if( $InputObject.ToString() -notlike ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($Contains.ToString())) )
                {
                    Fail $failureMessage
                }
            }
        }

        'DoesNotContain'
        {
            $interfaces = $InputObject.GetType().GetInterfaces()
            $failureMessage = @'
----------------------------------------------------------------------
{0}
----------------------------------------------------------------------

contains

----------------------------------------------------------------------
{1}
----------------------------------------------------------------------

{2}
'@ -f $InputObject,$DoesNotContain,$Message

            if( ($interfaces | Where-Object { $_.Name -eq 'IList' } ) )
            {
                if( $InputObject -contains $DoesNotContain )
                {
                    Fail $failureMessage
                    return
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'IDictionary' }) )
            {
                if( $InputObject.Contains( $DoesNotContain ) )
                {
                    Fail $failureMessage
                }
            }
            elseif( ($interfaces | Where-Object { $_.Name -eq 'ICollection' } ) )
            {
                $found = $false
                foreach( $item in $InputObject.GetEnumerator() )
                {
                    if( $item -eq $DoesNotContain )
                    {
                        $found = $true
                        break
                    }
                }

                if( $found )
                {
                    Fail $failureMessage
                }
            }
            else
            {
                if( $Contains -eq $null )
                {
                    $Contains = ''
                }

                if( $InputObject.ToString() -like ('*{0}*' -f [Management.Automation.WildcardPattern]::Escape($DoesNotContain.ToString())) )
                {
                    Fail $failureMessage
                }
            }
        }

        'DoesNotThrowException'
        {
            if( $InputObject -isnot [scriptblock] )
            {
                throw 'When using `DoesNotThrowException` parameter, `-InputObject` must be a ScriptBlock.'
            }

            try
            {
                Invoke-Command -ScriptBlock $InputObject
            }
            catch
            {
                Fail ('Script block threw an exception: {0}{1}{2}{1}{3}' -f $_.Exception.Message,([Environment]::NewLine),$_.ScriptStackTrace,$Message)
            }
        }

        'ThrowsException'
        {
            if( $InputObject -isnot [scriptblock] )
            {
                throw 'When using `Throws` parameter, `-InputObject` must be a ScriptBlock.'
            }

            $threwException = $false
            $ex = $null
            try
            {
                Invoke-Command -ScriptBlock $InputObject
            }
            catch
            {
                $ex = $_.Exception
                if( $ex -is $Throws )
                {
                    $threwException = $true
                }
                else
                {
                    Fail ('Expected ScriptBlock to throw a {0} exception, but it threw: {1}  {2}' -f $Throws,$ex,$Message)
                }
            }

            if( -not $threwException )
            {
                Fail ('ScriptBlock did not throw a ''{0}'' exception. {1}' -f $Throws.FullName,$Message)
            }

            if( $AndMessageMatches )
            {
                if( $ex.Message -notmatch $AndMessageMatches )
                {
                    Fail ('Exception message ''{0}'' doesn''t match ''{1}''.' -f $ex.Message,$AndMessageMatches)
                }
            }
        }
    }
}