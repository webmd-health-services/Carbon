<#
.SYNOPSIS
Runs Blade tests in a file or directory.

.DESCRIPTION
The `blade.ps1` script, located in the root of the Blade module, is the script used to execute Blade tests. Given a path, it runs tests in any PowerShell script that begins with `Test-` (i.e. that matches the wildcard pattern `Test-*.ps1`. Tests are functions that that use the `Test` verb (i.e. whose name match the `Test-*` wildcard pattern).

When executing tests, `blade.ps1` does the following:

 * Calls the `Start-TestFixture` function (if defined)
 * For each test, calls the `Start-Test` function (if defined), executes the test, then calls the `Stop-Test` (if defined).
 * Calls the `Stop-TestFixture` function (if defined)

By default, Blade returns `Blade.TestResult` objects for each failed test. 

After running all tests, `blade.ps1` will write an error if any tests failed, then write a summary of the test run. The results of the last test run is available as a `Blade.RunResult` object in a global `$LastBladeResult` variable, e.g.

    > .\Blade\blade.ps1 .\Test
    
       Count Failures   Errors  Ignored Duration        
       ----- --------   ------  ------- --------        
          47        0        0        0 00:00:11.6870000
    


    > $LastBladeResult | Format-List
    
    
    Count        : 47
    Name         : 
    Passed       : {Test-ShouldDetectNoErrors, Test-ShouldThrowErrorIfNeedleMissingFromFile, Test-ShouldFailIfFileZeroBytes, Test-ShouldFailIfFileEmpty...}
    Failures     : {}
    Errors       : {}
    IgnoredCount : 0
    Duration     : 00:00:11.6870000
    
    
    
If you want Blade to return objects for each test, regarless if it failed or not, use the `-PassThru` switch.

You can run specific test(s) by passing names to the `Test` parameter. Do not include the `Test-` verb/prefix.

`blade.ps1` can also save test results as an NUnit XML report, so you can integrate test results into build servers and other reporting tools. Use the `XmlLogPath` parameter to specify the path to a log file. The file, and its parent directories, will be created if it doesn't exist.


.LINK
about_Blade

.LINK
about_Blade_Objects

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
[CmdletBinding()]
param(
    [Parameter(Mandatory=$true,Position=0)]
    [string[]]
    # The paths to search for tests.  All files matching Test-*.ps1 will be run.
    $Path,

    [string]
    # The name of the tests being run.
    $Name,

    [string[]]
    # The individual test in the script to run. Defaults to all tests. Do not include the `Test-` verb/prefix.
    $Test,

    [string]
    # Path to the file where XML results should be saved. This file, and its parent directories, will be created if they don't exist.
    $XmlLogPath,
    
    [Switch]
    # Return objects for each test run, and a final summary object.
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
    Write-Debug -Message "Loading test script '$testScript'."
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
    
    Write-Debug -Message "Found $($tokens.Count) tokens in '$testScript'."
    
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
            Write-Debug -Message "Found function '$($token.Content).'"
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

    $testPassed = $false
    try
    {
        if( Test-path function:Start-Test )
        {
            . Start-Test | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        elseif( Test-Path function:SetUp )
        {
            Write-Warning ('The SetUp function is obsolete and will be removed in a future version of Blade. Please use Start-Test instead.')
            . SetUp | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        
        if( Test-Path function:$function )
        {
            . $function | ForEach-Object { $testInfo.Output.Add( $_ ) }
        }
        $testPassed = $true
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
        $tearDownResult = New-Object 'Blade.TestResult' $fixture,$function
        $tearDownFailed = $false
        try
        {
            if( Test-Path function:Stop-Test )
            {
                . Stop-Test | ForEach-Object { $tearDownResult.Output.Add( $_ ) }
            }
            elseif( Test-Path -Path function:TearDown )
            {
                Write-Warning ('The TearDown function is obsolete and will be removed in a future version of Blade. Please use Start-Test instead.')
                . TearDown | ForEach-Object { $tearDownResult.Output.Add( $_ ) }
            }
            $tearDownResult.Completed()
        }
        catch
        {
            $tearDownResult.Completed( $_ )
            $tearDownFailed = $true
        }
        finally
        {
            if( $testPassed )
            {
                $testInfo.Completed()
            }

            $flag = '! '
            $result = 'FAILED'
            if( $testInfo.Passed )
            {
                $flag = '  '
                $result = 'Passed'
            }
            Write-Verbose -Message ('  {0}{1} in {2:mm\:ss\.fff}  [{3}]' -f $flag,$result,$testInfo.Duration,$function)
            $testInfo
            if( $tearDownFailed )
            {
                $tearDownResult
            }
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
        
        Write-Verbose -Message ('[{0}]' -f $testCase.Name)

        . $testCase.FullName

        try
        {
            if( Test-Path -Path 'function:Start-TestFixture' )
            {
                . Start-TestFixture | Out-String | Write-Debug
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
                    . Stop-TestFixture | Out-String | Write-Debug
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

$Global:LastBladeResult = New-Object 'Blade.RunResult' $Name,([Blade.TestResult[]]$results), $testsIgnored
if( $LastBladeResult.Errors -or $LastBladeResult.Failures )
{
    Write-Error $LastBladeResult.ToString()
}

if( $XmlLogPath )
{
    $LastBladeResult | Export-RunResultXml -FilePath $XmlLogPath
}

$LastBladeResult | Format-Table | Out-Host
