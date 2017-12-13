
function Invoke-WhiskeyNodeTask
{
    <#
    .SYNOPSIS
    Runs a Node build.
    
    .DESCRIPTION
    The `Invoke-WhiskeyNodeTask` function runs Node builds. It uses NPM's `run` command to run a list of NPM scripts. These scripts are defined in your package.json file's `Scripts` property. If any script fails, the build will fail. This function checks if a script fails by looking at the exit code to `npm`. Any non-zero exit code is treated as a failure.

    You are required to specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed for you using NVM. 

    You may additionally specify a version of NPM to use in the engines field of your package.json file. NPM will be downloaded into your package's 'node_modules' directory at the specified version. This local version of NPM will be used to execute the list of `NpmScript` and then will be removed from 'node_modules' at the end of the build.

    This task accepts these parameters:

    * `NpmScript`: a list of one or more NPM scripts to run, e.g. `npm run SCRIPT_NAME`. Each script is run indepently.
    * `WorkingDirectory`: the directory where all the build commands should be run. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
    * `NpmRegistryUri` the uri to set a custom npm registry
    
    Here's a sample `whiskey.yml` using the Node task:

        BuildTasks:
        - Node:
          NpmScript:
          - build
          - test

    This task also does the following as part of each Node.js build:

    * Runs `npm install` to install your dependencies.
    * Runs NSP, the Node Security Platform, to check for any vulnerabilities in your depedencies.
    * Saves a report on each dependency's license.

    .EXAMPLE
    Invoke-WhiskeyNodeTask -TaskContext $context -TaskParameter @{ NpmScript = 'build','test', NpmRegistryUri = 'http://registry.npmjs.org/' }

    Demonstrates how to run the `build` and `test` NPM targets in the directory specified by the `$context.BuildRoot` property. The function would run `npm run build test`.
    #>
    [Whiskey.Task("Node",SupportsClean=$true, SupportsInitialize=$true)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context the task is running under.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The task parameters, which are:
        #
        # * `NpmScript`: a list of one or more NPM scripts to run, e.g. `npm run $SCRIPT_NAME`. Each script is run indepently.
        # * `WorkingDirectory`: the directory where all the build commands should be run. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
        # * `NpmRegistryUri` the uri to set a custom npm registry
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-Warning -Message ('The ''Node'' task has been deprecated and will be removed in a future version of Whiskey. It''s functionality has been broken up into individual smaller tasks, ''NpmInstall'', ''NpmRunScript'', ''NspCheck'', and ''NodeLicenseChecker''. Update the build configuration in ''{0}'' to use the new tasks.' -f $TaskContext.ConfigurationPath)

    $startedAt = Get-Date
    function Write-Timing
    {
        param(
            $Message
        )

        $now = Get-Date
        Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $startedAt),$Message)
    }

    if( $TaskContext.ShouldClean() )
    {
        Write-Timing -Message 'Cleaning'
        $nodeModulesPath = (Join-Path -path $TaskContext.BuildRoot -ChildPath 'node_modules')
        if( Test-Path $nodeModulesPath -PathType Container )
        {
            $outputDirectory = Join-Path -path $TaskContext.BuildRoot -ChildPath '.output' 
            $emptyDir = New-Item -Name 'TempEmptyDir' -Path $outputDirectory -ItemType 'Directory'
            Write-Timing -Message ('Emptying {0}' -f $nodeModulesPath)
            Invoke-WhiskeyRobocopy -Source $emptyDir -Destination $nodeModulesPath | Write-Debug
            Write-Timing -Message ('COMPLETE')
            Remove-Item -Path $emptyDir
            Remove-Item -Path $nodeModulesPath
        }
        return
    }

    $npmRegistryUri = $TaskParameter['NpmRegistryUri']
    if (-not $npmRegistryUri) 
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''NpmRegistryUri'' is mandatory. It should be the URI to the registry from which Node.js packages should be downloaded. E.g.,
        
        BuildTasks:
        - Node:
            NpmRegistryUri: https://registry.npmjs.org/
        '
    }

    $npmScripts = $TaskParameter['NpmScript']
    $npmScriptCount = $npmScripts | Measure-Object | Select-Object -ExpandProperty 'Count'
    $numSteps = 6 + $npmScriptCount
    $stepNum = 0

    $originalPath = $env:PATH
    $activity = 'Running Node Task'

    function Update-Progress
    {
        param(
            [Parameter(Mandatory=$true)]
            [string]
            $Status,

            [int]
            $Step
        )

        Write-Progress -Activity $activity -Status $Status.TrimEnd('.') -PercentComplete ($Step/$numSteps*100)
    }

    $workingDir = $TaskContext.BuildRoot
    if( $TaskParameter.ContainsKey('WorkingDirectory') )
    {
        $workingDir = $TaskParameter['WorkingDirectory'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'WorkingDirectory'
    }

    Push-Location -Path $workingDir
    try
    {
        Update-Progress -Status 'Validating package.json and starting installation of Node.js version required for this package (if required)' -Step ($stepNum++)
        Write-Timing -Message 'Installing Node.js'
        $nodePath = Install-WhiskeyNodeJs -RegistryUri $npmRegistryUri -ApplicationRoot $workingDir -ForDeveloper:$TaskContext.ByDeveloper
        Write-Timing -Message ('COMPLETE')
        if( -not $nodePath )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Node version required for this package failed to install. Please see previous errors for details.')
        }
        Update-Progress -Status ('Node.js version required for this package is installed') -Step ($stepNum++)

        $nodeRoot = $nodePath | Split-Path
        $npmGlobalPath = Join-Path -Path $nodeRoot -ChildPath 'node_modules\npm\bin\npm-cli.js' -Resolve
        if( -not $npmGlobalPath )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NPM didn''t get installed by NVM when installing Node. Please use NVM to uninstall this version of Node.')
        }

        Update-Progress -Status ('Getting path to the version of NPM required for this package') -Step ($stepNum++)
        Write-Timing -Message 'Resolving path to NPM.'
        $npmPath = Get-WhiskeyNPMPath -NodePath $nodePath -ApplicationRoot $workingDir
        Write-Timing -Message ('COMPLETE')
        if( -not $npmPath )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Could not locate version of NPM that is required for this package. Please see previous errors for details.')
        }

        Set-Item -Path 'env:PATH' -Value ('{0};{1}' -f $nodeRoot,$env:Path)

        $noColorArg = @()
        if( ($TaskContext.ByBuildServer) -or $Host.Name -ne 'ConsoleHost' )
        {
            $noColorArg = '--no-color'
        }

        Update-Progress -Status ('npm install') -Step ($stepNum++)
        Write-Timing -Message 'Installing Node.js modules.'
        & $nodePath $npmPath 'install' '--production=false' $noColorArg
        if( $LASTEXITCODE )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NPM command `npm install` failed with exit code {0}.' -f $LASTEXITCODE)
        }

        if( $TaskContext.ShouldInitialize() )
        {
            Write-Timing -Message 'Initialization complete.'
            return
        }

        if( -not $npmScripts )
        {
            Write-WhiskeyWarning -TaskContext $TaskContext -Message (@'
Property 'NpmScript' is missing or empty. Your build isn''t *doing* anything. The 'NpmScript' property should be a list of one or more npm scripts to run during your build, e.g.

BuildTasks:
- Node:
  NpmScript:
  - build
  - test           
'@)
        }

        # local version of npm gets removed by 'npm install', so call Get-WhiskeyNPMPath to download it again if necessary
        $npmPath = Get-WhiskeyNPMPath -NodePath $nodePath -ApplicationRoot $workingDir
        foreach( $script in $npmScripts )
        {
            Update-Progress -Status ('npm run {0}' -f $script) -Step ($stepNum++)
            Write-Timing -Message ('Running script ''{0}''.' -f $script)
            & $nodePath $npmPath 'run' $script '--scripts-prepend-node-path=auto' $noColorArg 
            Write-Timing -Message ('COMPLETE')
            if( $LASTEXITCODE )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NPM command `npm run {0}` failed with exit code {1}.' -f $script,$LASTEXITCODE)
            }
        }

        Update-Progress -Status ('nsp check') -Step ($stepNum++)
        $nodeModulesRoot = Join-Path -Path $nodeRoot -ChildPath 'node_modules'
        $nspPath = Join-Path -Path $nodeModulesRoot -ChildPath 'nsp\bin\nsp'
        $npmCmd = 'install'
        if( (Test-Path -Path $nspPath -PathType Leaf) )
        {
            $npmCmd = 'update'
        }

        Write-Timing -Message ('Installing NSP.')
        & $nodePath $npmPath $npmCmd 'nsp@2.7.0' '-g'
        Write-Timing -Message ('COMPLETE')
        if( -not (Test-Path -Path $nspPath -PathType Leaf) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NSP module failed to install to ''{0}''.' -f $nodeModulesRoot)
        }

        Write-Timing -Message ('Running NSP security check.')
        $output = & $nodePath $nspPath 'check' '--output' 'json' 2>&1 |
                        ForEach-Object { if( $_ -is [Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_ } } 
        Write-Timing -Message ('COMPLETE')
        $results = ($output -join [Environment]::NewLine) | ConvertFrom-Json
        if( $LASTEXITCODE )
        {
            $summary = $results | Format-List | Out-String
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NSP, the Node Security Platform, found the following security vulnerabilities in your dependencies (exit code: {0}):{1}{2}' -f $LASTEXITCODE,[Environment]::NewLine,$summary)
        }

        Update-Progress -Status ('license-checker') -Step ($stepNum++)
        $licenseCheckerPath = Join-Path -Path $nodeModulesRoot -ChildPath 'license-checker\bin\license-checker'
        $npmCmd = 'install'
        if( (Test-Path -Path $licenseCheckerPath -PathType Leaf) )
        {
            $npmCmd = 'update'
        }
        Write-Timing -Message ('Installing license checker.')
        & $nodePath $npmPath $npmCmd 'license-checker@latest' '-g'
        Write-Timing -Message ('COMPLETE')
        if( -not (Test-Path -Path $licenseCheckerPath -PathType Leaf) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('License Checker module failed to install to ''{0}''.' -f $nodeModulesRoot)
        }

        Write-Timing -Message ('Generating license report.')
        $reportJson = & $nodePath $licenseCheckerPath '--json'
        Write-Timing -Message ('COMPLETE')
        $report = ($reportJson -join [Environment]::NewLine) | ConvertFrom-Json
        if( -not $report )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('License Checker failed to output a valid JSON report.')
        }

        Write-Timing -Message ('Converting license report.')
        # The default license checker report has a crazy format. It is an object with properties for each module.
        # Let's transform it to a more sane format: an array of objects.
        [object[]]$newReport = $report | 
                                    Get-Member -MemberType NoteProperty | 
                                    Select-Object -ExpandProperty 'Name' | 
                                    ForEach-Object { $report.$_ | Add-Member -MemberType NoteProperty -Name 'name' -Value $_ -PassThru }

        # show the report
        $newReport | Sort-Object -Property 'licenses','name' | Format-Table -Property 'licenses','name' -AutoSize | Out-String | Write-Verbose

        $licensePath = 'node-license-checker-report.json'
        $licensePath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath $licensePath
        ConvertTo-Json -InputObject $newReport -Depth 100 | Set-Content -Path $licensePath
        Write-Timing -Message ('COMPLETE')
    }
    finally
    {
        Set-Item -Path 'env:PATH' -Value $originalPath

        Pop-Location

        Write-Progress -Activity $activity -Completed -PercentComplete 100
    }
}
