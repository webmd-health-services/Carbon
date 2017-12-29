
function Invoke-WhiskeyPester4Task
{
    <#
    .SYNOPSIS
    Runs Pester tests using Pester 4.

    .DESCRIPTION
    The `Pester4` task runs tests using Pester 4. You pass the path(s) to test to the `Path` property. If any test fails, the build will fail.

    Pester is installed using the PowerShellGet module's `Save-Module` function. The module is installed to the `Modules` directory in your build root. If the PowerShellGet module isn't installed, this task will fail.

    It is hard, in some build tools, to track down your longest running tests and Describe blocks. The `Pester4` task can output two reports that will show you the longest running It and Describe blocks. The `DescribeDurationReportCount` property controls how many rows to show in the Describe Duration Report, which shows the duration of every Describe block that was run, from longest to shortest duration. The `ItDurationReportCount` property controls how many rows to show in the It Duration Report, which shows the duration of all It blocks that were run, from longest to shortest durations.

    ## Properties

    * `Path` (mandatory): the path to the test scripts to run. These paths are passed to the `Invoke-Pester` function's `Script` parameter. Wildcards are supported, but they are resolved by the `Pester4` task *before* getting passed to Pester.
    * `Version`: the version of Pester 4 to use. Defaults to the latest version of Pester 4. Wildcards are supported if you want to pin to a specific minor version, e.g. `4.0.*` will use the latest `4.0` version, but never `4.1` or later.
    * `DescribeDurationReportCount`: the number of rows to show in the Describe Duration Report. The default is `0`. The Describe Duration Report shows Describe block execution durations in your build output, sorted by longest running to shortest running. This property controls how many rows to show in the report.
    * `ItDurationReportCount`: the number of rows to show in the It Duration Report. The default is `0`. The It Duration Report shows It block execution durations in your build output, sorted by longest running to shortest running. This property controls how many rows to show in the report.

    ## Examples

    ### Example 1

        BuildTasks:
        - Pester4:
            Path: Test\*.ps1

    Demonstrates how to run Pester tests using Pester 4. In this case, all the tests in files that match the wildcard `Test\*.ps1` are run.

    ### Example 2

        BuildTasks:
        - Pester4:
            Path: Test\*.ps1
            Version: 4.0.6

    Demonstrates how to pin to a specific version of Pester 4. In this case, Pester 4.0.6 will always be used.

    ### Example 3

        BuildTasks:
        - Pester4:
            Path: Test\*.ps1
            DescribeDurationReportCount: 20
            ItDurationReportCount: 20

    Demonstrates how to show the Describe Duration Report and It Duration Report after the task finishes. These reports show the duration of all Describe and It blocks that were run. In this example, the top 20 longest Describe and It blocks will be sho
    #>
    [Whiskey.Task("Pester4",SupportsClean=$true, SupportsInitialize=$true)]
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
    
    if( $ErrorActionPreference -eq [Management.Automation.ActionPreference]::Stop )
    {
        Write-Warning -Message ('The ErrorActionPreference variable is set to ''Stop''. This will cause Pester tests to stop at the first error. We recommend running builds with the ErrorActionPreference set to ''Continue''.')
    }

    if( $TaskParameter.ContainsKey('Version') )
    {
        $version = $TaskParameter['Version'] | ConvertTo-WhiskeySemanticVersion
        if( -not $version )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -message ('Property ''Version'' isn''t a valid version number. It must be a version number of the form MAJOR.MINOR.PATCH.')
        }

        if( $version.Major -ne 4)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Version property''s value ''{0}'' is invalid. It must start with ''4.'' (i.e. the major version number must always be ''4'')."' -f $version)
        }
        
        $version = [version]('{0}.{1}.{2}' -f $version.Major,$version.Minor,$version.Patch)
    }
    else
    {
        $version = '4.*'
    }

    if( $TaskContext.ShouldClean() )
    {
        Uninstall-WhiskeyTool -ModuleName 'Pester' -BuildRoot $TaskContext.BuildRoot -Version $version
        return
    }
    
    $pesterModulePath = Install-WhiskeyTool -DownloadRoot $TaskContext.BuildRoot -ModuleName 'Pester' -Version $version
    
    if( $TaskContext.ShouldInitialize() )
    {
        return
    }

    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should be one or more paths, which should be a list of Pester test scripts (e.g. Invoke-WhiskeyPester4Task.Tests.ps1) or directories that contain Pester test scripts, e.g. 
        
        BuildTasks:
        - Pester4:
            Path:
            - My.Tests.ps1
            - Tests')
    }

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    
    if( -not $pesterModulePath )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to download or install Pester {0}, most likely because version {0} does not exist. Available version numbers can be found at https://www.powershellgallery.com/packages/Pester' -f $version)
    }

    [int]$describeDurationCount = 0
    $describeDurationCount = $TaskParameter['DescribeDurationReportCount']
    [int]$itDurationCount = 0
    $itDurationCount = $TaskParameter['ItDurationReportCount']

    $testIdx = 0
    $outputFileNameFormat = 'pester-{0:00}.xml'
    while( (Test-Path -Path (Join-Path -Path $TaskContext.OutputDirectory -ChildPath ($outputFileNameFormat -f $testIdx))) )
    {
        $testIdx++
    }

    $outputFile = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ($outputFileNameFormat -f $testIdx)

    Write-Verbose -Message ('[Pester4]  {0}' -f $pesterModulePath)
    Write-Verbose -Message ('[Pester4]    Script      {0}' -f ($Path | Select-Object -First 1))
    $Path | Select-Object -Skip 1 | ForEach-Object { Write-Verbose -Message ('[Pester4]                {0}' -f $_) }
    Write-Verbose -Message ('[Pester4]    OutputFile  {0}' -f $outputFile)
    # We do this in the background so we can test this with Pester.
    $job = Start-Job -ScriptBlock {
        $script = $using:Path
        $pesterModulePath = $using:pesterModulePath
        $outputFile = $using:outputFile
        [int]$describeCount = $using:describeDurationCount
        [int]$itCount = $using:itDurationCount

        Invoke-Command -ScriptBlock {
                                        $VerbosePreference = 'SilentlyContinue'
                                        Import-Module -Name $pesterModulePath
                                    }

        $result = Invoke-Pester -Script $script -OutputFile $outputFile -OutputFormat NUnitXml -PassThru

        $result.TestResult | 
            Group-Object 'Describe' |
            ForEach-Object {
                $totalTime = [TimeSpan]::Zero
                $_.Group | ForEach-Object { $totalTime += $_.Time }
                [pscustomobject]@{
                                    Describe = $_.Name;
                                    Duration = $totalTime
                                }
            } | Sort-Object -Property 'Duration' -Descending |
            Select-Object -First $describeCount |
            Format-Table -AutoSize
        
        $result.TestResult |
            Sort-Object -Property 'Time' -Descending |
            Select-Object -First $itCount |
            Format-Table -AutoSize -Property 'Describe','Name','Time'
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
