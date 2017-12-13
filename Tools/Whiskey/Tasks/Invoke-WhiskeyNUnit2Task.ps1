function Invoke-WhiskeyNUnit2Task
{
    <#
    .SYNOPSIS
    Runs NUnit 2 tests.

    .DESCRIPTION
    Runs NUnit unit tests using the latest version of NUnit 2, currently 2.6.4. An XML report of the test results is saved to `.output\nunit-XX.xml` (where XX are numbers). The .output directory is in the same directory as your whiskey.yml file. The task installs the NUNit.Runners NuGet package from nuget.org into a `packages` directory in your repository root and uses the nunit-console.exe application from that package. 

    Tests are run through OpenCover, a code coverage tool. An OpenCover XML report is saved to `.output\opencover\openCover.xml`. OpenCover is installed with NuGet from nuget.org into a `packages` directory in the root of your repository. 

    An HTML code coverage report is generated from the openCover.xml file using Report Generator. Report Generator is installed with NuGet from nuget.org into a packages directory in the root of your repository. The HTML reports are saved to `.output\opencover`. The `.output` directory is in the same directory as your whiskey.yml file.

    You can disable code coverage with the `DisableCodeCoverage` property.

    ## Properties

    * **Path** (mandatory): the paths to the assemblies to test. Wildcards are allowed.
    * **Include**: The categories to run. Only tests and test fixtures with a Category attribute whose name matches a name from this list will be run. The default is to run all tests.  The value of this property is passed to the nunit-console.exe program's `/include` parameter as-is.
    * **Exclude**: A list of categories that shouldn't run. Tests and test fixtures with a Category attribute that matches an item in this list will not be run. The default is to run all tests.  The value of this property is passed to the nunit-console.exe program's `/exclude` parameter as-is.
    * **Framework**: The .NET framework to use when running tests. The default is 4.0. We're not sure what values are supported. NUnit's documentation doesn't list possible values.
    * **Argument**: Extra command-line arguments to pass to nunit-console.exe.
    * **OpenCoverVersion**: the version of OpenCover to use. The default is the latest version.
    * **ReportGeneratorVersion**: the version of ReportGenerator to use. The default is the latest version.
    * **DisableCodeCoverage**: doesn't run tests with OpenCover. No code coverage reports are generated.
    * **CoverageFilter**: A list of filters to apply to selectively include or exclude assemblies and classes from coverage results. The default is to include all assemblies. The OpenCover Usage page explains the filter syntax.
    * **OpenCoverArgument**: Extra command-line arguments to pass to OpenCover.Console.exe. The OpenCover Usage page details all available arguments.
    * **ReportGeneratorArgument**: Extra command-line arguments to pass to ReportGenerator.exe. The Report Generator Usage page details all available arguments.

    ## Examples

    ### Example 1
    
        BuildTasks:
        - NUnit2:
            Path:
            - UnitTests\bin\Whiskey.*.Tests.dll
            CoverageFilter: "+[Whiskey*]*"
    
    This example demonstrates how to call gather code coverage information using a coverage filter. In this case, all assemblies matching 'Whiskey*' will be part of the coverage report. The tests in all the assemblies in `UnitTests\bin` that match the wildcard `Whiskey.*.Tests.dll` would be run.

    ### Example 2
    
        BuildTasks:
        - NUnit2:
            Path:
            - UnitTests\bin\Whiskey.*.Tests.dll
            Include: Category 1,Category 2
            Exclude: Category 3,Category 4
            DisableCodeCoverage: true
    
    This example demonstrates how to only run tests from multiple categories and exclude tests from multiple categories when categories have spaces in their names and tests *are not* run with OpenCover. In this case, only tests with `Category 1` and `Category 2` categories will be run. If any of these tests also have categories `Category 3` or `Category 4`, they will not be run.

    ### Example 3
    
        BuildTasks:
        - NUnit2:
            Path:
            - UnitTests\bin\Whiskey.*.Tests.dll
            Include: '"Category 1,Category 2"'
            Exclude: '"Category 3,Category 4"'
            DisableCodeCoverage: true
    
    This example demonstrates how to only run tests from multiple categories and exclude tests from multiple categories when categories have spaces in their names and tests are run with OpenCover. You need to put double-quotes around the categories. In this case, only tests with `Category 1` and `Category 2` categories will be run. If any of these tests also have categories `Category 3` or `Category 4`, they will not be run.
    #>
    [Whiskey.Task("NUnit2",SupportsClean=$true, SupportsInitialize=$true)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $TaskContext,
    
        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )
    
    Set-StrictMode -version 'latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    $startedAt = Get-Date
    function Write-Timing
    {
        param(
            $Message
        )

        $now = Get-Date
        Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $startedAt),$Message)
    }

    $package = 'NUnit.Runners'
    $version = '2.6.4'
    if( $TaskParameter['Version'] )
    {
        $version = $TaskParameter['Version']
        if( $version -notlike '2.*' )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Version' -Message ('The version ''{0}'' isn''t a valid 2.x version of NUnit.' -f $TaskParameter['Version'])
        }
    }

    $openCoverVersionArg  = @{}
    $reportGeneratorVersionArg = @{}
    if( $TaskParameter['OpenCoverVersion'] )
    {
        $openCoverVersionArg['Version'] = $TaskParameter['OpenCoverVersion']
    }
    if( $TaskParameter['ReportGeneratorVersion'] )
    {
        $reportGeneratorVersionArg['Version'] = $TaskParameter['ReportGeneratorVersion']
    }
    
    $openCoverArgs = @()
    if( $TaskParameter['OpenCoverArgument'] )
    {
        $openCoverArgs += $TaskParameter['OpenCoverArgument']
    }
    
    $reportGeneratorArgs = @()
    if( $TaskParameter['ReportGeneratorArgument'] )
    {
        $reportGeneratorArgs += $TaskParameter['ReportGeneratorArgument']
    }
    
    if( $TaskContext.ShouldClean() )
    {
        Write-Timing -Message ('Uninstalling ReportGenerator.')
        Uninstall-WhiskeyTool -NuGetPackageName 'ReportGenerator' -BuildRoot $TaskContext.BuildRoot @reportGeneratorVersionArg
        Write-Timing -Message ('COMPLETE')
        Write-Timing -Message ('Uninstalling OpenCover.')
        Uninstall-WhiskeyTool -NuGetPackageName 'OpenCover' -BuildRoot $TaskContext.BuildRoot @openCoverVersionArg
        Write-Timing -Message ('COMPLETE')
        Write-Timing -Message ('Uninstalling NUnit.')
        Uninstall-WhiskeyTool -NuGetPackageName $package -BuildRoot $TaskContext.BuildRoot -Version $version
        Write-Timing -Message ('COMPLETE')
        return
    }

    $includeParam = $null
    if( $TaskParameter.ContainsKey('Include') )
    {
        $includeParam = '/include={0}' -f $TaskParameter['Include']
    }
        
    $excludeParam = $null
    if( $TaskParameter.ContainsKey('Exclude') )
    {
        $excludeParam = '/exclude={0}' -f $TaskParameter['Exclude']
    }

    $frameworkParam = '4.0'
    if( $TaskParameter.ContainsKey('Framework') )
    {
        $frameworkParam = $TaskParameter['Framework']
    }
    $frameworkParam = '/framework={0}' -f $frameworkParam
      
    Write-Timing -Message ('Installing NUnit.')
    $nunitRoot = Install-WhiskeyTool -NuGetPackageName $package -Version $version -DownloadRoot $TaskContext.BuildRoot
    Write-Timing -Message ('COMPLETE')
    if( -not (Test-Path -Path $nunitRoot -PathType Container) )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Package {0} {1} failed to install!' -f $package,$version)
    }
    $nunitRoot = Get-Item -Path $nunitRoot | Select-Object -First 1
    $nunitRoot = Join-Path -Path $nunitRoot -ChildPath 'tools'
    $nunitConsolePath = Join-Path -Path $nunitRoot -ChildPath 'nunit-console.exe' -Resolve
    if( -not ($nunitConsolePath))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('{0} {1} was installed, but couldn''t find nunit-console.exe at ''{2}''.' -f $package,$version,$nunitConsolePath)
    }

    Write-Timing -Message ('Installing OpenCover.')
    $openCoverRoot = Install-WhiskeyTool -NuGetPackageName 'OpenCover' -DownloadRoot $TaskContext.BuildRoot @openCoverVersionArg
    Write-Timing -Message ('COMPLETE')
    if( -not (Test-Path -Path $openCoverRoot -PathType Container))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to install NuGet package OpenCover {0}.' -f $version)
    }
    $openCoverPath = Get-ChildItem -Path $openCoverRoot -Filter 'OpenCover.Console.exe' -Recurse |
                        Select-Object -First 1 |
                        Select-Object -ExpandProperty 'FullName'
    if( -not (Test-Path -Path $openCoverPath -PathType Leaf) )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Unable to find OpenCover.Console.exe in OpenCover NuGet package at ''{0}''.' -f $openCoverRoot)
    }

    Write-Timing -Message ('Installing ReportGenerator.')
    $reportGeneratorRoot = Install-WhiskeyTool -NuGetPackageName 'ReportGenerator' -DownloadRoot $TaskContext.BuildRoot @reportGeneratorVersionArg
    Write-Timing -Message ('COMPLETE')
    if( -not (Test-Path -Path $reportGeneratorRoot -PathType Container))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to install NuGet package ReportGenerator.' -f $version)
    }
    $reportGeneratorPath = Get-ChildItem -Path $reportGeneratorRoot -Filter 'ReportGenerator.exe' -Recurse |
                                Select-Object -First 1 |
                                Select-Object -ExpandProperty 'FullName'
    if( -not (Test-Path -Path $reportGeneratorPath -PathType Leaf) )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Unable to find ReportGenerator.exe in ReportGenerator NuGet package at ''{0}''.' -f $reportGeneratorRoot)
    }

    if( $TaskContext.ShouldInitialize() )
    {
        return
    }

    # Be sure that the Taskparameter contains a 'Path'.
    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should be one or more paths, which should be a list of assemblies whose tests to run, e.g. 
        
        BuildTasks:
        - NUnit2:
            Path:
            - Assembly.dll
            - OtherAssembly.dll')
    }

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    $reportPath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('nunit2-{0:00}.xml' -f $TaskContext.TaskIndex)

    $coverageReportDir = Join-Path -Path $TaskContext.outputDirectory -ChildPath "opencover"
    New-Item -Path $coverageReportDir -ItemType 'Directory' -Force | Out-Null
    $openCoverReport = Join-Path -Path $coverageReportDir -ChildPath 'openCover.xml'
    
    $extraArgs = $TaskParameter['Argument'] | Where-Object { $_ }
    $VerbosePreference = 'Continue'
    Write-Verbose -Message ('  Path                {0}' -f ($Path | Select-Object -First 1))
    $Path | Select-Object -Skip 1 | ForEach-Object { Write-Verbose -Message ('                      {0}' -f $_) }
    Write-Verbose -Message ('  Framework           {0}' -f $frameworkParam)
    Write-Verbose -Message ('  Include             {0}' -f $includeParam)
    Write-Verbose -Message ('  Exclude             {0}' -f $excludeParam)
    Write-Verbose -Message ('  Argument            /xml={0}' -f $reportPath)
    $extraArgs | ForEach-Object { Write-Verbose -Message ('                      {0}' -f $_) }
    Write-Verbose -Message ('  CoverageFilter      {0}' -f ($TaskParameter['CoverageFilter'] | Select-Object -First 1))
    $TaskParameter['CoverageFilter'] | Select-Object -Skip 1 | ForEach-Object { Write-Verbose -Message ('                      {0}' -f $_) }
    Write-Verbose -Message ('  Output              {0}' -f $openCoverReport)
    $disableCodeCoverage = $TaskParameter['DisableCodeCoverage'] | ConvertFrom-WhiskeyYamlScalar
    Write-Verbose -Message ('  DisableCodeCoverage {0}' -f $disableCodeCoverage)
    Write-Verbose -Message ('  OpenCoverArgs       {0}' -f ($openCoverArgs | Select-Object -First 1))
    $openCoverArgs | Select-Object -Skip 1 | ForEach-Object { Write-Verbose -Message ('                      {0}' -f $_) }
    Write-Verbose -Message ('  ReportGeneratorArgs {0}' -f ($reportGeneratorArgs | Select-Object -First 1))
    $reportGeneratorArgs | Select-Object -Skip 1 | ForEach-Object { Write-Verbose -Message ('                      {0}' -f $_) }
    
    if( -not $disableCodeCoverage )
    {
        $coverageFilterString = ($TaskParameter['CoverageFilter'] -join " ")
        $extraArgString = ($extraArgs -join " ")
        $pathsArg = ($path -join '" "')
        $nunitArgs = '"{0}" /noshadow {1} /xml="{2}" {3} {4} {5}' -f $pathsArg,$frameworkParam,$reportPath,$includeParam,$excludeParam,$extraArgString
        $nunitArgs = $nunitArgs -replace '"', '\"'
        Write-Timing -Message ('Running OpenCover')
        & $openCoverPath "-target:${nunitConsolePath}" "-targetargs:${nunitArgs}" "-filter:${coverageFilterString}" '-register:user' "-output:${openCoverReport}" '-returntargetcode' $openCoverArgs
        Write-Timing -Message ('COMPLETE')
        $testsFailed = $LastExitCode;
        Write-Timing -Message ('Running ReportGenerator')
        & $reportGeneratorPath "-reports:${openCoverReport}" "-targetdir:$coverageReportDir" $reportGeneratorArgs
        Write-Timing -Message ('COMPLETE')
        if( $LastExitCode -or $testsFailed )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NUnit2 tests failed. {0} returned exit code {1}.' -f $openCoverPath,$LastExitCode)
        }
    }
    else
    {
        Write-Timing -Message ('Running NUnit')
        & $nunitConsolePath $path $frameworkParam $includeParam $excludeParam $extraArgs ('/xml={0}' -f $reportPath)
        Write-Timing -Message ('COMPLETE')
        if( $LastExitCode )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NUnit2 tests failed. {0} returned exit code {1}.' -f $nunitConsolePath,$LastExitCode)
        }
    }
}
