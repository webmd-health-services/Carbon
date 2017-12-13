
function Invoke-WhiskeyNodeLicenseChecker
{
    <#
    .SYNOPSIS
    Generates a report of each dependency's license.
    
    .DESCRIPTION
    The `NodeLicenseChecker` task runs the node module `license-checker` against all the modules listed in the `dependencies` and `devDepenendencies` properties of the `package.json` file for this application. The task will create a JSON report file named `node-license-checker-report.json` located in the `.output` directory of the build root.

    You must specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed for you using NVM. 

    If the application's `package.json` file does not exist in the build root next to the `whiskey.yml` file, specify a `WorkingDirectory` where it can be found.

    # Properties

    # * `NpmRegistryUri` (mandatory): the uri to set a custom npm registry.
    # * `WorkingDirectory`: the directory where the `package.json` exists. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.

    # Examples

    ## Example 1

        BuildTasks:
        - NodeLicenseChecker:
            NpmRegistryUri: "http://registry.npmjs.org"
    
    This example will run `license-checker` against the modules listed in the `package.json` file located in the build root.

    ## Example 2

        BuildTasks:
        - NodeLicenseChecker:
            NpmRegistryUri: "http://registry.npmjs.org"
            WorkingDirectory: app
    
    This example will run `license-checker` against the modules listed in the `package.json` file that is located in the `(BUILD_ROOT)\app` directory.
    #>

    [Whiskey.Task("NodeLicenseChecker", SupportsClean=$true, SupportsInitialize=$true)]
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

    $startedAt = Get-Date
    function Write-Timing
    {
        param(
            $Message
        )

        $now = Get-Date
        Write-Debug -Message ('[{0}]  [{1}]  {2}' -f $now,($now - $startedAt),$Message)
    }

    $npmRegistryUri = $TaskParameter['NpmRegistryUri']
    if (-not $npmRegistryUri) 
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''NpmRegistryUri'' is mandatory. It should be the URI to the registry from which Node.js packages should be downloaded, e.g.,
        
        BuildTasks:
        - NodeLicenseChecker:
            NpmRegistryUri: https://registry.npmjs.org/

        '
    }

    $workingDirectory = $TaskContext.BuildRoot
    if ($TaskParameter['WorkingDirectory'])
    {
        $workingDirectory = $TaskParameter['WorkingDirectory'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'WorkingDirectory'
    }

    if ($TaskContext.ShouldClean())
    {
        Write-Timing -Message 'Cleaning'
        Uninstall-WhiskeyNodeModule -Name 'npm' -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper -Force
        Uninstall-WhiskeyNodeModule -Name 'license-checker' -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper -Force
        Write-Timing -Message 'COMPLETE'
        return
    }

    Write-Timing -Message 'Installing license-checker'
    $licenseCheckerModuleRoot = Install-WhiskeyNodeModule -Name 'license-checker' -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper
    $licenseCheckerPath = Join-Path -Path $licenseCheckerModuleRoot -ChildPath 'bin\license-checker' -Resolve -ErrorAction Ignore
    
    if (-not $licenseCheckerPath)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to download the ''license-checker'' module to ''{0}''.' -f (Join-Path -Path $workingDirectory -ChildPath 'node_modules'))
    }
    Write-Timing -Message 'COMPLETE'

    if ($TaskContext.ShouldInitialize())
    {
        Write-Timing -Message 'Initialization Complete'
        return
    }

    Push-Location -Path $workingDirectory
    try
    {
        $nodePath = Install-WhiskeyNodeJs -RegistryUri $npmRegistryUri -ApplicationRoot $workingDirectory -ForDeveloper:$TaskContext.ByDeveloper

        Write-Timing -Message ('Generating license report')
        $reportJson = Invoke-Command -NoNewScope -ScriptBlock {
            & $nodePath $licenseCheckerPath '--json'
        }
        Write-Timing -Message ('COMPLETE')

        $report = Invoke-Command -NoNewScope -ScriptBlock {
            ($reportJson -join [Environment]::NewLine) | ConvertFrom-Json
        }
        if (-not $report)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message 'License Checker failed to output a valid JSON report.'
        }

        Write-Timing -Message 'Converting license report.'
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
        Pop-Location
    }
}
