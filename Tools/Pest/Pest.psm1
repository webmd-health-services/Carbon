
$currentTest = $null

Add-Type @"
namespace Pest
{
    public sealed class AssertionException : System.Exception
    {
        private string[] _psStackTrace;
        
        public AssertionException(string message, string[] psStackTrace) : base(message)
        {
            _psStackTrace = psStackTrace;
        }

        public string[] PSStackTrace 
        { 
            get { return _psStackTrace; }
        }  
    }
}
"@

function Set-CurrentTest($currentTest)
{
    $SCRIPT:currentTest = $currentTest
}

function Assert-Contains($haystack, $needle, $message)
{
    if( $haystack -notcontains $needle )
    {
        Fail "Unable to find '$needle': $message"
    }
}

function Assert-ContainsLike($haystack, $needle, $message)
{
    foreach( $line in $haystack )
    {
        if( $line -like "*$needle*" )
        {
            return
        }
    }
    Fail "Unable to find '$needle': $message" 
}

function Assert-ContainsNotLike($haystack, $needle, [Parameter(Mandatory=$true)]$message)
{
    foreach( $line in $haystack )
    {
        if( $line -like "*$needle*" )
        {
            Fail "Found '$needle': $message"
        }
    }
}


function Assert-DirectoryDoesNotExist($directory, $message)
{
    if( Test-Path $directory -PathType Container )
    {
        Fail "Directory '$directory' exists: $message"
    }
}

function Assert-DirectoryExists($directory, $message)
{
    if( -not (Test-Path $directory -PathType Container) )
    {
        Fail "Directory $directory does not exist: $message"
    }
}

function Assert-DoesNotContain($Haystack, $Needle, $Message)
{
    if( $Haystack -contains $Needle )
    {
        Fail "Found '$Needle': $Message"
    }
}

function Assert-Empty($item, $message)
{
    if( $item -and ($item.Length -gt 0 -or $item.Count -gt 0) )
    {
        Fail "Expected '$item' to be empty: $message"
    }
}

function Assert-Equal($expected, $actual, $message)
{
    Write-TestVerbose "Is '$expected' -eq '$actual'?"
    if( -not ($expected -eq $actual) )
    {
        if( $expected -is [string] -and $actual -is [string] -and ($expected.Contains("`n") -or $actual.Contains("`n")))
        {
            for( $idx = 0; $idx -lt $expected.Length; ++$idx )
            {
                if( $idx -gt $actual.Length )
                {
                    Fail "Strings different, beginning at index $idx:`n$($expected.Substring(0,$idx))`n($actual)`n$message"
                }
                
                if( $expected[$idx] -ne $actual[$idx] )
                {
                    Fail "Strings different beginning at index $idx: $idx`n$($expected.Substring(0,$idx))`n$($actual.Substring(0,$idx))`n$message"
                }
            }
            
        }
        Fail "Expected '$expected', but was '$actual': $message"
    }
}

function Assert-CEqual
{
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Expected,
        [Parameter(Mandatory=$true)]
        [string]
        $Actual,
        [Parameter(Mandatory=$true)]
        [string]
        $Message
    )
    if( $Expected -cne $Actual )
    {
        for( $idx = 0; $idx -lt $expected.Length; ++$idx )
        {
            if( $idx -gt $actual.Length )
            {
                Fail "Strings different, beginning at index $idx:`n$($expected.Substring(0,$idx))`n($actual)`n$message"
            }
            
            if( $expected[$idx] -cne $actual[$idx] )
            {
                $actualSnippet = if( ($idx + 1) -gt $actual.Length ) { $Actual } else { $Actual.Substring(0, $idx) }
                Fail "Strings different beginning at index $idx: $idx`n$($expected.Substring(0,$idx + 1))`n$actualSnippet`n$message"
            }
        }

        Fail "Expected '$Expected', but was '$Actual': $Message"
    }
}

function Assert-False($expected, $message)
{
    if( $expected )
    {
        Fail "Expected false, but was true: $message"
    }
}

function Assert-FileContains($file, $expectedContents, $message)
{
    Write-TestVerbose "Checking if '$file' contains expected content."
    $actualContents = (Get-Content $file) -Join "`n"
    Write-TestVerbose "Actual:`n$actualContents"
    Write-TestVerbose "Expected:`n$expectedContents"
    if( -not $actualContents.Contains($expectedContents) )
    {
        Fail "File '$file' does not contain expected contents: $message"
    }
}

function Assert-FileDoesNotExist($file, $message)
{
    if( Test-Path $file -PathType Leaf )
    {
        Fail "File $file exists: $message"
    }
}

function Assert-FileExists($file, $message)
{
    Write-TestVerbose "Testing if file '$file' exists."
    if( -not (Test-Path $file -PathType Leaf) )
    {
        Fail "File $file does not exist.  $message"
    }
}

function Assert-GreaterThan($expectedValue, $lowerBound, $message)
{
    if( -not ($expectedValue -gt $lowerBound ) )
    {
        Fail "'$expectedValue' is not greater than '$lowerbound': $message"
    }
}

function Assert-Is($object, $expectedType)
{
    if( -not ($object -is $expectedType) )
    {
        Fail "Expected object to be of type '$expectedType' but was $($object.GetType())."
    }
}

function Assert-IsNull($value, $message)
{
    if( $value -ne $null )
    {
        Fail "Value '$value' is not null: $message"
    }
}

function Assert-IsNotNull($value, $message)
{
    if( $value -eq $null )
    {
        Fail "Value is null: $message"
    }
}

function Assert-LastProcessFailed($message)
{
    if( $LastExitCode -eq 0 )
    {
        Fail "Expected process to fail, but it succeeded (exit code: $lastExitCode).  $message" 
    }
}

function Assert-LastProcessSucceeded($message)
{
    if( $LastExitCode -ne 0 )
    {
        Fail "Expected process to succeed, but it failed (exit code: $lastExitCode).  $message" 
    }
}

function Assert-LastPipelineError($expectedError, $message)
{
    if( $error[0] -notmatch $expectedError )
    {
        Fail "Last error '$($error[0].Message)' did not match '$expectedError'." 
    }
}

function Assert-LessThan($expectedValue, $upperBound, $message)
{
    if( -not ($expectedValue -lt $upperBound) )
    {
        Fail "$expectedValue is not less than $upperBound : $message" 
    }
}

function Assert-Like($haystack, $needle, $message)
{
    if( $haystack -notlike "*$needle*" )
    {
        Fail "'$haystack' is not like '$needle': $message" 
    }
}

function Assert-Match
{
    param(
        [Parameter(Position=0,Mandatory=$true)]
        # The string that should match the regular expression
        $Haystack, 
        
        [Parameter(Position=1,Mandatory=$true)]
        # The regular expression to use when matching.
        $Regex, 
        
        [Parameter(Position=2,Mandatory=$true)]
        # The message to show when the assertion fails.
        $Message
    )
    
    if( $haystack -notmatch $regex )
    {
        Fail "'$haystack' does not match '$regex': $message"
    }
}

function Assert-NoErrors($message)
{
    if( $error.Count -gt 0 )
    {
        Fail "Found $($error.Count) errors, expected none.  $message" 
    }
}

function Assert-NodeDoesNotExist($xml, $xpath, $defaultNamespacePrefix, $message)
{
    if( Test-NodeExists $xml $xpath $defaultNamespacePrefix )
    {
        Fail "Found node with xpath '$xpath': $message"
    }
}

function Assert-NodeExists($xml, $xpath, $defaultNamespacePrefix, $message)
{
    if( -not (Test-NodeExists $xml $xpath $defaultNamespacePrefix) )
    {
        Fail "Couldn't find node with xpath '$xpath': $message"
    }
}

function Test-NodeExists($xml, $xpath, $defaultNamespacePrefix)
{
    $nsManager = New-Object System.Xml.XmlNamespaceManager( $xml.NameTable )
    if( $xml.DocumentElement.NamespaceURI -ne '' -and $xml.DocumentElement.Prefix -eq '' )
    {
        Write-TestVerbose "XML document has a default namespace, setting prefix to '$defaultNamespacePrefix'."
        $nsManager.AddNamespace($defaultNamespacePrefix, $xml.DocumentElement.NamespaceURI)
    }
    
    $node = $xml.SelectSingleNode( $xpath, $nsManager )
    return $node -ne $null
}

function Assert-NotEqual($expected, $actual, $message)
{
    if( $expected -eq $actual )
    {
        Fail "Expected '$expected' to be different than '$actual': $message"
    }
}

function Assert-NotEmpty($item, $message)
{
    if( -not ($item) -or ($item.Length -eq 0 -or $item.Count -eq 0) )
    {
        Fail  "Found empty variable: $message"
    }
}

function Assert-NotNull($object, $message)
{
    Assert-IsNotNull $object $message
}

function Assert-Null($object, $message)
{
    Assert-IsNull $object $message
}

function Assert-True($condition, $message)
{
    if( -not $condition )
    {
        Fail  "Expected true but was false: $message"
    }
}

function Fail($message)
{
    $scopeNum = 0
    $stackTrace = @()
    
    foreach( $item in (Get-PSCallStack) )
    {
        $invocationInfo = $item.InvocationInfo
        $stackTrace +=  "$($item.ScriptName):$($item.ScriptLineNumber) $($invocationInfo.MyCommand)"
    }

    $ex = New-Object 'Pest.AssertionException' $message,$stackTrace
    throw $ex
}

function Remove-ItemWithRetry($item, [Switch]$Recurse)
{
    if( -not (Test-Path $item) )
    {
        return
    }
    
    $RecurseParam = if( $Recurse ) { '-Recurse' } else { '' }
    $numTries = 0
    do
    {
        if( -not (Test-Path $item) )
        {
            return $true
        }
        
        if( $Recurse )
        {
            Remove-Item $item -Recurse -Force -ErrorAction SilentlyContinue
        }
        else
        {
            Remove-Item $item -Force -ErrorAction SilentlyContinue
        }
        
        if( Test-Path $item )
        {
            Start-Sleep -Milliseconds 100
        }
        else
        {
            return $true
        }
        $numTries += 1
    }
    while( $numTries -lt 20 )
    return $false
}

function Write-TestVerbose($message)
{
    Write-Verbose $message
}

function Set-TestVerbosity($verbosity)
{
    $Script:VerbosePreference = $verbosity
}

function New-TempDir
{
    <#
    .SYNOPSIS
    Creates a new temporary directory.
    #>
    $tmpPath = [System.IO.Path]::GetTempPath()
    $newTmpDirName = [System.IO.Path]::GetRandomFileName()
    New-Item (Join-Path $tmpPath $newTmpDirName) -Type Directory
}

