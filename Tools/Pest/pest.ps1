<#

.SYNOPSIS

Runs pest tests in a file or set of directories.

.DESCRIPTION

Pest is a testing framework for PowerShell.  Test fixtures are defined in files
that begin with "Test-".  Each test can have a Setup and Teardown function,
which are run before each test.  Any method in a test fixture file that begins 
with "Test-" is run.

Output is captured and written to verbose output.

.EXAMPLE

.EXAMPLE

.\pest Test-MyScript.ps1

Will run all the tests Test-MyScript.ps1 script.

.EXAMPLE

.\pest Test-MyScript.ps1 -Test MyTest

Will run the MyTest test in the MyScript test script.

.EXAMPLE

pest .\MyModule

Will run all Test-*.ps1 scripts under the .\MyModule directory.

#>

[CmdletBinding(DefaultParameterSetName='SingleScript')]
param(
    [Parameter(Position=0,ParameterSetName='SingleScript', Mandatory=$true)]
    # The script to run.
    $Script,
    
    [Parameter(ParameterSetName='SingleScript')]
    # The individual test in the script to run.  Defaults to all tests.
    $Test = $null,
    
    [Parameter(ParameterSetName='MultipleScripts',Mandatory=$true)]
    [string[]]
    # The paths to search for tests.  All files matching Test-*.ps1 will be run.
    $Path
)

$ErrorActionPreference = 'Stop'

$PSScriptRoot = Split-Path $myInvocation.MyCommand.Definition

Write-Verbose "PSScriptRoot: $PSScriptRoot"

Import-Module $PSScriptRoot -Force

$modules = @{ }
Get-Module | % { $modules[$_.Name] = $true }

Set-TestVerbosity $VerbosePreference

function Exit-Pest($exitCode = 0)
{
    if( (Get-Module Pest) -ne $null )
    {
        Remove-Module Pest
    }
    exit($exitCode)
}

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
        Exit-Pest -1 
    }
    
    Write-Verbose "Found $($tokens.Count) tokens in '$testScript'."
    
    $functions = New-Object System.Collections.ArrayList
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

function Resolve-Error ($ErrorRecord=$Error[0])
{
   $ErrorRecord | Format-List * -Force
   $ErrorRecord.InvocationInfo |Format-List *
   $Exception = $ErrorRecord.Exception
   for ($i = 0; $Exception; $i++, ($Exception = $Exception.InnerException))
   {   "$i" * 80
       $Exception |Format-List * -Force
   }
}

function Invoke-Test($function)
{
    Set-CurrentTest $function
    try
    {
        
        if( Test-path function:Setup )
        {
            . SetUp | Write-Verbose
        }
        
        if( Test-Path function:$function )
        {
            Write-Output "$function"
            $script:testsRun++
            . $function | Write-Verbose
        }
    }
    catch [Pest.AssertionException]
    {
        $ex = $_.Exception
        $script:testsFailed++
        Write-Host "$($ex.Message)`n  at $($ex.PSStackTrace -join "`n  at ")" -ForegroundColor Red
        continue
    }
    catch
    {
        if( $_.Exception.Message -eq 'Cannot bind argument to parameter ''Message'' because it is null.' )
        {
            Write-Warning 'It looks like your test is adding a null object to the command pipeline.'
        }
        else
        {
            $script:testErrors++
            for( $idx = 0; $idx -lt $error.Count; ++$idx )
            {
                $err = $error[$idx]
                #Resolve-Error $err
                $errInfo = $err.InvocationInfo
                Write-Host "$($err)`n$($errInfo.PositionMessage.Trim())" -ForegroundColor Red
            }
        }
        continue
    }
    finally
    {
        $error.Clear()
        if( Test-Path function:TearDown )
        {
            try
            {
                . TearDown | Write-Verbose
            }
            catch
            {
                Write-Host "An error occured tearing down test '$function': $_" -ForegroundColor Red
                $error.Clear()
            }
        }
    }
}

$testScripts = if( $Script -eq $null) { Get-ChildItem $Path Test-*.ps1 -Recurse } else { @( (Get-Item $Script) ) }
if( $testScripts -eq $null )
{
    $testScripts = @()
}

$error.Clear()
$testsRun = 0
$testsFailed = 0
$testsIgnored = 0
$testErrors = 0
$TestScript = $null
$TestDir = $null
$startedAt = Get-Date

foreach( $testCase in $testScripts )
{
    $TestScript = (Resolve-Path $testCase.FullName).Path
    $TestDir = Split-Path -Parent $testCase.FullName 
    
    $testModuleName =  [System.IO.Path]::GetFileNameWithoutExtension($testCase)
    Write-Output "# $testModuleName #"

    $functions = Get-FunctionsInFile $testCase.FullName
    
    if( $functions -contains "Test-$Test" )
    {
        $functions = @( "Test-$Test" )
    }
    elseif( $functions -contains "Ignore-$Test" )
    {
        $functions = @( "Ignore-$Test" )
    }
    
    . $testCase.FullName
    try
    {
        
        foreach( $function in $functions )
        {

            if( $function -like 'Ignore-*' )
            {
                if( $function -ne "Ignore-$Test" )
                {
                    Write-Warning "Skipping ignored test '$function'."
                    $testsIgnored++
                    continue
                }
            }
            elseif( $function -notlike 'Test-*' )
            {
                continue
            }
            
            Invoke-Test $function
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
        
        # if we don't unload any modules loaded by the test, they get cached by PowerShell 
        # and subsequent runs of the test script won't reload the updated module.
        Get-Module | % {
            if( -not $modules.ContainsKey( $_.Name ) )
            {
                Remove-Module $_.Name
            }
        }
    }        
}

$timeTook = (Get-Date) - $startedAt
Write-Output "Ran $testsRun test(s) with $testsFailed failure(s), $testErrors error(s), and $testsIgnored ignored in $($timeTook.TotalSeconds) second(s)."
$exitCode = (-$testsFailed)
if( $testErrors -gt 0 )
{
    $exitCode = $testErrors
}
Exit-Pest $exitCode