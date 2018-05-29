
function Invoke-WhiskeyNodeTask
{
    <#
    .SYNOPSIS
    ** OBSOLETE ** Use the `NpmInstall`, `NpmRunScript`, `NodeNspCheck`, and `NodeLicenseChecker` tasks instead.
    
    .DESCRIPTION
    ** OBSOLETE ** Use the `NpmInstall`, `NpmRunScript`, `NodeNspCheck`, and `NodeLicenseChecker` tasks instead.
    #>
    [Whiskey.Task('Node',SupportsClean=$true,SupportsInitialize=$true)]
    [Whiskey.RequiresTool('Node','NodePath')]
    [Whiskey.RequiresTool('NodeModule::license-checker','LicenseCheckerPath',VersionParameterName='LicenseCheckerVersion')]
    [Whiskey.RequiresTool('NodeModule::nsp','NspPath',VersionParameterName='PINNED_TO_NSP_2_7_0',Version='2.7.0')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The context the task is running under.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The task parameters, which are:
        #
        # * `NpmScript`: a list of one or more NPM scripts to run, e.g. `npm run $SCRIPT_NAME`. Each script is run indepently.
        # * `WorkingDirectory`: the directory where all the build commands should be run. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Write-Warning -Message ('The ''Node'' task has been deprecated and will be removed in a future version of Whiskey. It''s functionality has been broken up into individual smaller tasks, ''NpmInstall'', ''NpmRunScript'', ''NodeNspCheck'', and ''NodeLicenseChecker''. Update the build configuration in ''{0}'' to use the new tasks.' -f $TaskContext.ConfigurationPath)

    if( $TaskContext.ShouldClean )
    {
        Write-WhiskeyTiming -Message 'Cleaning'
        $nodeModulesPath = Join-Path -path $TaskContext.BuildRoot -ChildPath 'node_modules'
        Remove-WhiskeyFileSystemItem -Path $nodeModulesPath
        Write-WhiskeyTiming -Message 'COMPLETE'
        return
    }

    $npmScripts = $TaskParameter['NpmScript']
    $npmScriptCount = $npmScripts | Measure-Object | Select-Object -ExpandProperty 'Count'
    $numSteps = 4 + $npmScriptCount
    $stepNum = 0

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

    $workingDirectory = (Get-Location).ProviderPath
    $originalPath = $env:PATH

    try
    {
        $nodePath = Assert-WhiskeyNodePath -Path $TaskParameter['NodePath'] -ErrorAction Stop
        $nodeRoot = $nodePath | Split-Path

        Set-Item -Path 'env:PATH' -Value ('{0};{1}' -f $nodeRoot,$env:Path)

        Update-Progress -Status ('Installing NPM packages') -Step ($stepNum++)
        Write-WhiskeyTiming -Message ('npm install')
        Invoke-WhiskeyNpmCommand -Name 'install' -ArgumentList '--production=false' -NodePath $nodePath -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
        Write-WhiskeyTiming -Message ('COMPLETE')

        if( $TaskContext.ShouldInitialize )
        {
            Write-WhiskeyTiming -Message 'Initialization complete.'
            return
        }

        if( -not $npmScripts )
        {
            Write-WhiskeyWarning -TaskContext $TaskContext -Message (@'
Property 'NpmScript' is missing or empty. Your build isn''t *doing* anything. The 'NpmScript' property should be a list of one or more npm scripts to run during your build, e.g.

Build:
- Node:
  NpmScript:
  - build
  - test           
'@)
        }

        foreach( $script in $npmScripts )
        {
            Update-Progress -Status ('npm run {0}' -f $script) -Step ($stepNum++)
            Write-WhiskeyTiming -Message ('Running script ''{0}''.' -f $script)
            Invoke-WhiskeyNpmCommand -Name 'run-script' -ArgumentList $script -NodePath $nodePath -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
            Write-WhiskeyTiming -Message ('COMPLETE')
        }

        Update-Progress -Status ('nsp check') -Step ($stepNum++)
        Write-WhiskeyTiming -Message ('Running NSP security check.')
        $nspPath = Assert-WhiskeyNodeModulePath -Path $TaskParameter['NspPath'] -CommandPath 'bin\nsp' -ErrorAction Stop
        $output = & $nodePath $nspPath 'check' '--output' 'json' 2>&1 |
                        ForEach-Object { if( $_ -is [Management.Automation.ErrorRecord]) { $_.Exception.Message } else { $_ } }
        Write-WhiskeyTiming -Message ('COMPLETE')
        $results = ($output -join [Environment]::NewLine) | ConvertFrom-Json
        if( $LASTEXITCODE )
        {
            $summary = $results | Format-List | Out-String
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NSP, the Node Security Platform, found the following security vulnerabilities in your dependencies (exit code: {0}):{1}{2}' -f $LASTEXITCODE,[Environment]::NewLine,$summary)
        }

        Update-Progress -Status ('license-checker') -Step ($stepNum++)
        Write-WhiskeyTiming -Message ('Generating license report.')

        $licenseCheckerPath = Assert-WhiskeyNodeModulePath -Path $TaskParameter['LicenseCheckerPath'] -CommandPath 'bin\license-checker' -ErrorAction Stop

        $reportJson = & $nodePath $licenseCheckerPath '--json'
        Write-WhiskeyTiming -Message ('COMPLETE')
        $report = ($reportJson -join [Environment]::NewLine) | ConvertFrom-Json
        if( -not $report )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('License Checker failed to output a valid JSON report.')
        }

        Write-WhiskeyTiming -Message ('Converting license report.')
        # The default license checker report has a crazy format. It is an object with properties for each module.
        # Let's transform it to a more sane format: an array of objects.
        [object[]]$newReport = $report | 
                                    Get-Member -MemberType NoteProperty | 
                                    Select-Object -ExpandProperty 'Name' | 
                                    ForEach-Object { $report.$_ | Add-Member -MemberType NoteProperty -Name 'name' -Value $_ -PassThru }

        # show the report
        $newReport | Sort-Object -Property 'licenses','name' | Format-Table -Property 'licenses','name' -AutoSize | Out-String | Write-WhiskeyVerbose -Context $TaskContext

        $licensePath = 'node-license-checker-report.json'
        $licensePath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath $licensePath
        ConvertTo-Json -InputObject $newReport -Depth 100 | Set-Content -Path $licensePath
        Write-WhiskeyTiming -Message ('COMPLETE')
    }
    finally
    {
        Set-Item -Path 'env:PATH' -Value $originalPath
        Write-Progress -Activity $activity -Completed -PercentComplete 100
    }
}
