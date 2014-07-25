<#
.SYNOPSIS
Runs Blade tests in a file or set of directories.

.DESCRIPTION
Blade is a simple testing framework, inspired by NUnit.  It reads in all the files under a given path (or paths), and opens each file that matches the `Test-*` pattern.  It will then execute the tests in that file.  Blade tests are functions that that use the `Test` verb in their name, i.e. whose name match the `Test-*` pattern.

When executing the tests in a file, Blade does the following:

 * Calls the `Start-TestFixture` function (if one is defined)
 * Executes each test.  For each test, Blade calls the `Start-Test` function (if defined), followed by the test, followed by the `Stop-Test` function (if defined).
 * Calls the `Stop-TestFixture` function (if one is defined)

Blade will return `Blade.TestResult` objects for all failed tests and a final `Blade.RunResult` object summarizing the results.  Use the `PassThru` switch to also get `Blade.TestResult` objects for passing tests.

You can access the `Blade.RunResult` object from the last test run via the global `LASTBLADERESULT` variable.

.LINK
about_Blade

.EXAMPLE
.\blade Test-MyScript.ps1

Will run all the tests in the `Test-MyScript.ps1` script.

.EXAMPLE
.\blade Test-MyScript.ps1 -Test MyTest

Will run the `MyTest` test in the `Test-MyScript.ps1` test script.

.EXAMPLE
blade .\MyModule

Will run all tests in the files which match the `Test-*.ps1` wildcard in the .\MyModule directory.

.EXAMPLE
blade .\MyModule -Recurse

Will run all test in files which match the `Test-*.ps1` wildcard under the .\MyModule directory and its sub-directories.

#>
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
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string[]]
    # The paths to search for tests.  All files matching Test-*.ps1 will be run.
    $Path,
    
    [string[]]
    # The individual test in the script to run.  Defaults to all tests.
    $Test,
    
    [Switch]
    # Return objects for each test run.
    $PassThru,
    
    [Switch]
    # Recurse through directories under `$Path` to find tests.
    $Recurse
)

#Requires -Version 3
Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Import-Blade.ps1' -Resolve)

function Get-FunctionsInFile($testScript)
{
    Write-Verbose "Loading test script '$testScript'."
    $testScriptContent = Get-Content "$testScript"
    if( -not $testScriptContent )
    {
        return @()
    }

    $errors = [Management.Automation.PSParseError[]] @()
    $tokens = [System.Management.Automation.PsParser]::Tokenize( $testScriptContent, [ref] $errors )
    if( $errors -ne $null -and $errors.Count -gt 0 )
    {
        Write-Error "Found $($errors.count) error(s) parsing '$testScript'."
        return
    }
    
    Write-Verbose "Found $($tokens.Count) tokens in '$testScript'."
    
    $functions = New-Object System.Collections.ArrayList
    $atFunction = $false
    for( $idx = 0; $idx -lt $tokens.Count; ++$idx )
    {
        $token = $tokens[$idx]
        if( $token.Type -eq 'Keyword'-and $token.Content -eq 'Function' )
        {
            $atFunction = $true
        }
        
        if( $atFunction -and $token.Type -eq 'CommandArgument' -and $token.Content -ne '' )
        {
            Write-Verbose "Found function '$($token.Content).'"
            [void] $functions.Add( $token.Content )
            $atFunction = $false
        }
    }
    
    return $functions.ToArray()
}

function Invoke-Test
{
    <#
    .SYNOPSIS
    PRIVATE. Invokes a test from a fixture.

    .DESCRIPTION
    Internal function.  Do not use.
    #>
    [CmdletBinding()]
    param(
        $fixture, 
        $function
    )

    Set-StrictMode -Version 'Latest'

    [Blade.TestResult]$testInfo = New-Object 'Blade.TestResult' $fixture,$function

    $Error.Clear()

    try
    {
        if( Test-path function:Start-Test )
        {
            . Start-Test | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        elseif( Test-Path function:SetUp )
        {
            . SetUp | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        
        if( Test-Path function:$function )
        {
            . $function | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }

        $testInfo.Completed()
    }
    catch [Blade.AssertionException]
    {
        $ex = $_.Exception
        $testInfo.Completed( $ex )
    }
    catch
    {
        $testInfo.Completed( $_ )
    }
    finally
    {
        $testInfo
        try
        {
            $tearDownResult = New-Object 'Blade.TestResult' $fixture,'Stop-Test'
            if( Test-Path function:Stop-Test )
            {
                . Stop-Test | ForEach-Object { $tearDownResult.Output.Add( $_ ) }
            }
            elseif( Test-Path -Path function:TearDown )
            {
                . TearDown | ForEach-Object { $tearDownResult.Output.Add( $_ ) }
            }
        }
        catch
        {
            $tearDownResult.Completed( $_ )
            $tearDownResult
        }

        $Error.Clear()
    }

}

$getChildItemParams = @{ }
if( $Recurse )
{
    $getChildItemParams.Recurse = $true
}

$testScripts = @( Get-ChildItem $Path Test-*.ps1 @getChildItemParams )
if( $testScripts -eq $null )
{
    $testScripts = @()
}

$Error.Clear()
$testsIgnored = 0
$TestScript = $null
$TestDir = $null

$results = $null
$testScripts | 
    ForEach-Object {
        $testCase = $_
        $TestScript = (Resolve-Path $testCase.FullName).Path
        $TestDir = Split-Path -Parent $testCase.FullName 
        
        $testModuleName =  [System.IO.Path]::GetFileNameWithoutExtension($testCase)

        $functions = Get-FunctionsInFile $testCase.FullName |
                        Where-Object { $_ -match '^(Test|Ignore)-(.*)$' } |
                        Where-Object { 
                            if( $PSBoundParameters.ContainsKey('Test') )
                            {
                                return $Test | Where-Object { $Matches[2] -like $_ } 
                            }

                            if( $Matches[1] -eq 'Ignore' )
                            {
                                Write-Warning ("Skipping ignored test '{0}'." -f $_)
                                $testsIgnored++
                                return $false
                            }

                            return $true
                        }
        if( -not $functions )
        {
            return
        }

        @('Start-TestFixture','Start-Test','Setup','TearDown','Stop-Test','Stop-TestFixture') |
            ForEach-Object { Join-Path -Path 'function:' -ChildPath $_ } |
            Where-Object { Test-Path -Path $_ } |
            Remove-Item
        
        . $testCase.FullName
        try
        {
            if( Test-Path -Path 'function:Start-TestFixture' )
            {
                . Start-TestFixture | Write-Verbose
            }

            foreach( $function in $functions )
            {

                if( -not (Test-Path -Path function:$function) )
                {
                    continue
                }
                
                Invoke-Test $testModuleName $function
            }

            if( Test-Path -Path function:Stop-TestFixture )
            {
                try
                {
                    . Stop-TestFixture | Write-Verbose
                }
                catch
                {
                    Write-Error ("An error occured tearing down test fixture '{0}': {1}" -f $testCase.Name,$_)
                    $result = New-Object 'Blade.TestResult' $testModuleName,'Stop-TestFixture'
                    $result.Finished( $_ )
                }                
            }
        }
        finally
        {
            foreach( $function in $functions )
            {
                if( $function -and (Test-Path function:$function) )
                {
                    Remove-Item function:\$function
                }
            }
        }        
    } | 
    Tee-Object -Variable 'results' |
    Where-Object { $PassThru -or -not $_.Passed } 

$Global:LastBladeResult = New-Object 'Blade.RunResult' ([Blade.TestResult[]]$results), $testsIgnored
if( $LastBladeResult.Errors -or $LastBladeResult.Failures )
{
    Write-Error $LastBladeResult.ToString()
}
$LastBladeResult | Format-Table | Out-Host

