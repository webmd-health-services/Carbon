
function Invoke-WhiskeyNspCheck
{
    <#
    .SYNOPSIS
    Runs the Node Security Platform against a module's dependenices.
    
    .DESCRIPTION
    The `NspCheck` task runs `node.exe nsp check`, the Node Security Platform, which checks a `package.json` and `npm-shrinkwrap.json` for known security vulnerabilities against the Node Security API. The latest version of the NSP module will be downloaded into the local `node_modules` directory located next to the module's `package.json` file. To use a specific version of the NSP module, include it in either the `devDependencies` or `dependencies` of the `package.json` file. If any security vulnerabilties are found the NSP module returns a non-zero exit code which will fail the task.

    You must specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed for you using NVM. 

    If the application's `package.json` file does not exist in the build root next to the `whiskey.yml` file, specify a `WorkingDirectory` where it can be found.

    # Properties

    # * `NpmRegistryUri` (mandatory): the uri to set a custom npm registry.
    # * `WorkingDirectory`: the directory where the `package.json` exists. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.

    # Examples

    ## Example 1

        BuildTasks:
        - NspCheck:
            NpmRegistryUri: "http://registry.npmjs.org"
    
    This example will run `node.exe nsp check` against the modules listed in the `package.json` file located in the build root.

    ## Example 2

        BuildTasks:
        - NspCheck:
            NpmRegistryUri: "http://registry.npmjs.org"
            WorkingDirectory: app
    
    This example will run `node.exe nsp check` against the modules listed in the `package.json` file that is located in the `(BUILD_ROOT)\app` directory.
    #>

    [Whiskey.Task("NspCheck", SupportsClean=$true, SupportsInitialize=$true)]
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
        - NspCheck:
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
        Uninstall-WhiskeyNodeModule -Name 'nsp' -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper -Force
        Write-Timing -Message 'COMPLETE'
        return
    }

    Write-Timing -Message 'Installing NSP'
    $nspModuleRoot = Install-WhiskeyNodeModule -Name 'nsp' -Version '2.7.0' -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper
    $nspPath = Join-Path -Path $nspModuleRoot -ChildPath 'bin\nsp' -Resolve -ErrorAction Ignore
    
    if (-not $nspPath)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to download the ''nsp'' module to ''{0}''.' -f (Join-Path -Path $workingDirectory -ChildPath 'node_modules'))
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

        Write-Timing -Message 'Running NSP security check'

        $output = Invoke-Command -NoNewScope -ScriptBlock {
            & $nodePath $nspPath 'check' '--output' 'json'
        }
        Write-Timing -Message 'COMPLETE'

        $results = ($output -join [Environment]::NewLine) | ConvertFrom-Json
        if ($Global:LASTEXITCODE -ne 0)
        {
            $summary = $results | Format-List | Out-String
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NSP, the Node Security Platform, found the following security vulnerabilities in your dependencies (exit code: {0}):{1}{2}' -f $LASTEXITCODE,[Environment]::NewLine,$summary)
        }
    }
    finally
    {
        Pop-Location
    }
}
