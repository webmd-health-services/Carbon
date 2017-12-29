
function Invoke-WhiskeyPester3Task
{
    <#
    .SYNOPSIS
    Runs Pester tests using Pester 3.

    .DESCRIPTION
    The `Invoke-Pester3Task` runs tests using Pester 3. You pass the path(s) to test to the `Path` parameter, which are passed directly to the `Invoke-Pester` function's `Script` parameter. Additional configuration information can be included in the `$TaskContext` such as:

    * `$TaskParameter.Version`: The version of Pester 3 to use. Can be a version between 3.0 but less than 4.0. Must match a version on the Powershell Gallery. To find a list of all the versions of Pester available, install the Package Management module, then run `Find-Module -Name 'Pester' -AllVersions`. You usually want the latest version.

    If any tests fail (i.e. if the `FailedCount property on the result object returned by `Invoke-Pester` is greater than 0), this function will throw a terminating error.

    .EXAMPLE
    Invoke-WhiskeyPester3Task -TaskContext $context -TaskParameter $taskParameter

    Demonstrates how to run Pester tests against a set of test fixtures. In this case, The version of Pester in `$TaskParameter.Version` will recursively run all tests under `TaskParameter.Path` and output an XML report with the results in the `$TaskContext.OutputDirectory` directory.
    #>
    [Whiskey.Task("Pester3",SupportsClean=$true, SupportsInitialize=$true)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,
    
        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $TaskParameter.ContainsKey('Version') )
    {
        $version = $TaskParameter['Version'] | ConvertTo-WhiskeySemanticVersion
        if( -not $version )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -message ('Property ''Version'' isn''t a valid version number. It must be a version number of the form MAJOR.MINOR.PATCH.')
        }

        if( $version.Major -ne 3)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Version property''s value ''{0}'' is invalid. It must start with ''3.'' (i.e. the major version number must always be ''3'')."' -f $version)
        }
        
        $version = [version]('{0}.{1}.{2}' -f $version.Major,$version.Minor,$version.Patch)
    }
    else
    {
        $version = '3.*'
    }

    if( $TaskContext.ShouldClean() )
    {
        Uninstall-WhiskeyTool -ModuleName 'Pester' -BuildRoot $TaskContext.BuildRoot -Version $version
        return
    }
    
    $pesterModulePath = Install-WhiskeyTool -ModuleName 'Pester' -Version $version -DownloadRoot $TaskContext.BuildRoot

    if( $TaskContext.ShouldInitialize() )
    {
        return
    }

    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should be one or more paths, which should be a list of Pester Tests to run with Pester3, e.g. 
        
        BuildTasks:
        - Pester3:
            Path:
            - My.Tests.ps1
            - Tests')
    }

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    
    if( -not $pesterModulePath )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to download or install Pester {0}, most likely because version {0} does not exist. Available version numbers can be found at https://www.powershellgallery.com/packages/Pester' -f $version)
    }

    $testIdx = 0
    $outputFileNameFormat = 'pester-{0:00}.xml'
    while( (Test-Path -Path (Join-Path -Path $TaskContext.OutputDirectory -ChildPath ($outputFileNameFormat -f $testIdx))) )
    {
        $testIdx++
    }

    $outputFile = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ($outputFileNameFormat -f $testIdx)

    # We do this in the background so we can test this with Pester.
    $job = Start-Job -ScriptBlock {
        $script = $using:Path
        $pesterModulePath = $using:pesterModulePath
        $outputFile = $using:outputFile

        Invoke-Command -ScriptBlock {
                                        $VerbosePreference = 'SilentlyContinue'
                                        Import-Module -Name $pesterModulePath
                                    }

        $env:PSModulePath | Write-Verbose -Verbose
        Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml -PassThru
    } 
    
    do
    {
        $job | Receive-Job
    }
    while( -not ($job | Wait-Job -Timeout 1) )

    $job | Receive-Job

    Publish-WhiskeyPesterTestResult -Path $outputFile

    $result = [xml](Get-Content -Path $outputFile -Raw)

    if( -not $result )
    {
        throw ('Unable to parse Pester output XML report ''{0}''.' -f $outputFile)
    }

    if( $result.'test-results'.errors -ne '0' -or $result.'test-results'.failures -ne '0' )
    {
        throw ('Pester tests failed.')
    }
}

