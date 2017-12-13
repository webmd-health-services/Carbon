
function Invoke-WhiskeyNUnit3Task
{
    <#
    .SYNOPSIS
    Runs NUnit3 tests.

    .DESCRIPTION
    The NUnit3 task runs NUnit tests. The latest version of NUnit 3 is downloaded from nuget.org for you (into a `packages` directory in your build root).
    
    The `Path` parameter is mandatory and must contain a list of paths, relative to your `whiskey.yml` file, to the assemblies for which NUnit tests should be run.

    By default, OpenCover runs NUnit and gathers test code coverage, saving its report to '.output\openCover\openCover.xml'. ReporterGenerator is used to convert the OpenCover report into an HTML report, viewable to '.output\openCover\index.html'. If you wish to **only** run NUnit tests, then specify the `DisableCodeCoverage` parameter with the value of `true`.
    
    The task will run NUnit tests with .NET framework `4.0` by default. You may override this setting with the `Framework` parameter.
        
    The task will fail if any of the NUnit tests fail (i.e. if the NUnit console returns a non-zero exit code).

    # Properties

    * `Path` (*mandatory*): the path, relative to your `whiskey.yml` file, to the assemblies for which you want to run NUnit tests for.
    * `TestFilter`: a list of expressions indicating which tests to run. It may specify test names, classes, methods, categories, or properties comparing them with the actual values with the operators ==, !=, =~, and !=. The documentation for this expression language can be found here: https://github.com/nunit/docs/wiki/Test-Selection-Language If multiple `TestFilter` are given then they will be joined with a logical `or` operator.
    * `Framework`: framework type/version to use for tests. e.g. 4.0, 4.5, mono-4.0. The default is `4.0`.
    * `Argument`: a list of additional arguments to pass to the NUnit3 console.
    * `DisableCodeCoverage`: boolean value indicating whether or to run the NUnit test results against OpenCover and ReportGenerator.
    * `CoverageFilter`: a list of OpenCover filters to apply to selectively include or exclude assemblies and classes from OpenCover coverage results.
    * `OpenCoverVersion`: the version of OpenCover to use. Defaults to the latest version available.
    * `OpenCoverArgument`: a list of additional arguments to pass to the OpenCover console.
    * `ReportGeneratorVersion`: the version of ReportGenerator to use. Defaults to the latest version available.
    * `ReportGeneratorArgument`: a list of additional arguments to pass to the ReportGenerator console.

    .EXAMPLE

    # Example 1

        BuildTasks:
        - NUnit3:
            Path:
            - RootAssembly.dll
            - subfolder\subAssembly.dll

    This example will run the NUnit tests for both the `RootAssembly.dll` and the `<build root>\subfolder\subAssembly.dll` with the default .NET framework version `4.0`. OpenCover and ReportGenerator will also be run against the results of the NUnit tests.

    # Example 2

        BuildTasks:
        - NUnit3:
            Path:
            - Assembly.dll
            Framework: 4.5
            DisableCodeCoverage: true

    This example will run the NUnit tests for the `Assembly.dll` file using .NET framework 4.5. OpenCover and ReportGenerator will not be run after the NUnit tests have completed since `DisableCodeCoverage` was `true`.

    # Example 3

        BuildTasks:
        - NUnit3:
            Path:
            - Assembly.dll
            TestFilter:
            - "cat == 'Slow Data Tests' && Priority == High"
            - "cat == 'Standard Tests'"
            Argument:
            - "--debug"

    This example will run the NUnit tests for the `Assembly.dll` file using the TestFilter of `(cat == 'Slow Data Tests' && Priority == High) or (cat == 'Standard Tests')` to select which tests to run. The NUnit console will be executed with the additional given argument `--debug`.

    # Example 4

        BuildTasks:
        - NUnit3:
            Path:
            - Assembly.dll
            CoverageFilter:
            - "+[Open*]*"
            - "-[Open.Test]*"
            OpenCoverVersion: 4.6.519
            OpenCoverArgument:
            - "-showunvisited"
            ReportGeneratorVersion: 2.5.11
            ReportGeneratorArgument:
            - "-reporttypes: Latex"
            - "-verbosity:Verbose"

    This example will run all tests located in the `Assembly.dll` file using the default .NET framework version `4.0`. OpenCover version `4.6.519` will be run against against the NUnit test results with the `CoverageFilter` `+[Open*]* -[Open.Test]*` and with the argument `-showunvisited`. ReportGenerator version `2.5.11` will be run against the OpenCover results using the arguments `-reporttypes:Latex` and `-verbosity:Verbose`.
    #>

    [CmdletBinding()]
    [Whiskey.Task("NUnit3",SupportsClean=$true,SupportsInitialize=$true)]
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

    $nunitPackage = 'NUnit.ConsoleRunner'
    # Due to a bug in NuGet we can't search for and install packages with wildcards (e.g. 3.*), so we're hardcoding a version for now. See Resolve-WhiskeyNuGetPackageVersion for more details.
    $nunitVersion = '3.7.0'
    if( $TaskParameter['Version'] )
    {
        $nunitVersion = $TaskParameter['Version']
        if( $nunitVersion -notlike '3.*' )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Version' -Message ('The version ''{0}'' isn''t a valid 3.x version of NUnit.' -f $TaskParameter['Version'])
        }
    }

    $nunitReport = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('nunit3-{0:00}.xml' -f $TaskContext.TaskIndex)
    $nunitReportParam = '--result={0}' -f $nunitReport

    $openCoverVersionParam = @{}
    if ($TaskParameter['OpenCoverVersion'])
    {
        $openCoverVersionParam['Version'] = $TaskParameter['OpenCoverVersion']
    }

    $reportGeneratorVersionParam = @{}
    if ($TaskParameter['ReportGeneratorVersion'])
    {
        $reportGeneratorVersionParam['Version'] = $TaskParameter['ReportGeneratorVersion']
    }

    if ($TaskContext.ShouldClean())
    {
        Uninstall-WhiskeyTool -NuGetPackageName $nunitPackage -BuildRoot $TaskContext.BuildRoot -Version $nunitVersion
        Uninstall-WhiskeyTool -NuGetPackageName 'OpenCover' -BuildRoot $TaskContext.BuildRoot @openCoverVersionParam
        Uninstall-WhiskeyTool -NuGetPackageName 'ReportGenerator' -BuildRoot $TaskContext.BuildRoot @reportGeneratorVersionParam
        return
    }

    $nunitPath = Install-WhiskeyTool -NuGetPackageName $nunitPackage -Version $nunitVersion -DownloadRoot $TaskContext.BuildRoot
    if (-not $nunitPath)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Package ''{0}'' failed to install.' -f $nunitPackage)
    }

    $openCoverPath = Install-WhiskeyTool -NuGetPackageName 'OpenCover' -DownloadRoot $TaskContext.BuildRoot @openCoverVersionParam
    if (-not $openCoverPath)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Package ''OpenCover'' failed to install.'
    }

    $reportGeneratorPath = Install-WhiskeyTool -NuGetPackageName 'ReportGenerator' -DownloadRoot $TaskContext.BuildRoot @reportGeneratorVersionParam
    if (-not $reportGeneratorPath)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Package ''ReportGenerator'' failed to install.'
    }

    if ($TaskContext.ShouldInitialize())
    {
        return
    }

    $openCoverArgument = @()
    if ($TaskParameter['OpenCoverArgument'])
    {
        $openCoverArgument = $TaskParameter['OpenCoverArgument']
    }
    
    $reportGeneratorArgument = @()
    if ($TaskParameter['ReportGeneratorArgument'])
    {
        $reportGeneratorArgument = $TaskParameter['ReportGeneratorArgument']
    }

    $framework = '4.0'
    if ($TaskParameter['Framework'])
    {
        $framework = $TaskParameter['Framework']
    }
    $frameworkParam = '--framework={0}' -f $framework

    $testFilter = ''
    $testFilterParam = ''
    if ($TaskParameter['TestFilter'])
    {
        $testFilter = $TaskParameter['TestFilter'] | ForEach-Object { '({0})' -f $_ }
        $testFilter = $testFilter -join ' or '
        $testFilterParam = '--where={0}' -f $testFilter
    }

    $nunitExtraArgument = ''
    if ($TaskParameter['Argument'])
    {
        $nunitExtraArgument = $TaskParameter['Argument']
    }

    $disableCodeCoverage = $TaskParameter['DisableCodeCoverage'] | ConvertFrom-WhiskeyYamlScalar

    $coverageFilter = ''
    if ($TaskParameter['CoverageFilter'])
    {
        $coverageFilter = $TaskParameter['CoverageFilter'] -join ' '
    }

    $nunitConsolePath = Join-Path -Path $nunitPath -ChildPath 'tools\nunit3-console.exe'
    $openCoverConsolePath = Join-Path $openCoverPath -ChildPath 'tools\OpenCover.Console.exe'
    $reportGeneratorConsolePath = Join-Path -Path $reportGeneratorPath -ChildPath 'tools\ReportGenerator.exe'

    foreach ($consolePath in @($nunitConsolePath, $openCoverConsolePath, $reportGeneratorConsolePath))
    {
        if (-not(Test-Path -Path $consolePath -PathType Leaf))
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Package ''{0}'' was installed, but could not locate ''{1}'' at {2}''.'-f ($consolePath | Split-Path | Split-Path -Leaf), ($consolePath | Split-Path -Leaf), $consolePath)
        }
    }

    if (-not $TaskParameter['Path'])
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Path'' is mandatory. It should be one or more paths to the assemblies whose tests should be run, e.g.

            BuildTasks:
            - NUnit3:
                Path:
                - Assembly.dll
                - OtherAssembly.dll

        ')
    }

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    $path | Foreach-Object {
        if (-not (Test-Path -Path $_ -PathType Leaf))
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('''Path'' item ''{0}'' does not exist.' -f $_)
        }
    }

    $coverageReportDir = Join-Path -Path $TaskContext.outputDirectory -ChildPath "opencover"
    New-Item -Path $coverageReportDir -ItemType 'Directory' -Force | Out-Null
    $openCoverReport = Join-Path -Path $coverageReportDir -ChildPath 'openCover.xml'
    
    $separator = '{0}VERBOSE:                       ' -f [Environment]::NewLine
    Write-Verbose -Message ('  Path                {0}' -f ($Path -join $separator))
    Write-Verbose -Message ('  Framework           {0}' -f $framework)
    Write-Verbose -Message ('  TestFilter          {0}' -f $testFilter)
    Write-Verbose -Message ('  Argument            {0}' -f ($nunitExtraArgument -join $separator))
    Write-Verbose -Message ('  NUnit Report        {0}' -f $nunitReport)
    Write-Verbose -Message ('  CoverageFilter      {0}' -f $coverageFilter)
    Write-Verbose -Message ('  OpenCover Report    {0}' -f $openCoverReport)
    Write-Verbose -Message ('  DisableCodeCoverage {0}' -f $disableCodeCoverage)
    Write-Verbose -Message ('  OpenCoverArgs       {0}' -f ($openCoverArgument -join ' '))
    Write-Verbose -Message ('  ReportGeneratorArgs {0}' -f ($reportGeneratorArgument -join ' '))
    
    $nunitExitCode = 0
    $reportGeneratorExitCode = 0
    $openCoverExitCode = 0
    $openCoverExitCodeOffset = 1000

    if (-not $disableCodeCoverage)
    {

        $path = $path | ForEach-Object { '\"{0}\"' -f $_ }
        $path = $path -join ' '

        $nunitReportParam = '\"{0}\"' -f $nunitReportParam

        if ($frameworkParam)
        {
            $frameworkParam = '\"{0}\"' -f $frameworkParam
        }

        if ($testFilterParam)
        {
            $testFilterParam = '\"{0}\"' -f $testFilterParam
        }

        if ($nunitExtraArgument)
        {
            $nunitExtraArgument = $nunitExtraArgument | ForEach-Object { '\"{0}\"' -f $_ }
            $nunitExtraArgument = $nunitExtraArgument -join ' '
        }

        $openCoverNunitArguments = '{0} {1} {2} {3} {4}' -f $path,$frameworkParam,$testFilterParam,$nunitReportParam,$nunitExtraArgument
        & $openCoverConsolePath "-target:$nunitConsolePath" "-targetargs:$openCoverNunitArguments" "-filter:$coverageFilter" "-output:$openCoverReport" -register:user -returntargetcode:$openCoverExitCodeOffset $openCoverArgument

        if ($LASTEXITCODE -ge 745)
        {
            $openCoverExitCode = $LASTEXITCODE - $openCoverExitCodeOffset
        }
        else
        {
            $nunitExitCode = $LASTEXITCODE
        }

        & $reportGeneratorConsolePath "-reports:$openCoverReport" "-targetdir:$coverageReportDir" $reportGeneratorArgument
        $reportGeneratorExitCode = $LASTEXITCODE
    }
    else 
    {
        & $nunitConsolePath $path $frameworkParam $testFilterParam $nunitReportParam $nunitExtraArgument
        $nunitExitCode = $LASTEXITCODE

    }

    if ($reportGeneratorExitCode -ne 0)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('ReportGenerator didn''t run successfully. ''{0}'' returned exit code ''{1}''.' -f $reportGeneratorConsolePath,$reportGeneratorExitCode)
    }
    elseif ($openCoverExitCode -ne 0)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('OpenCover didn''t run successfully. ''{0}'' returned exit code ''{1}''.' -f $openCoverConsolePath, $openCoverExitCode)
    }
    elseif ($nunitExitCode -ne 0)
    {
        if (-not (Test-Path -Path $nunitReport -PathType Leaf))
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NUnit3 didn''t run successfully. ''{0}'' returned exit code ''{1}''.' -f $nunitConsolePath,$nunitExitCode)
        }
        else
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NUnit3 tests failed. ''{0}'' returned exit code ''{1}''.' -f $nunitConsolePath,$nunitExitCode)
        }
    }
}
