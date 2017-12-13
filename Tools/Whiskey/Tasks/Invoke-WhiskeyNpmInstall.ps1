
function Invoke-WhiskeyNpmInstall
{
    <#
    .SYNOPSIS
    Installs Node.js packages.

    .DESCRIPTION
    The `NpmInstall` task will use NPM's `install` command to install Node.js packages. If not given any `Package`, the task will run `npm install` to install all packages listed in the `package.json` `dependency` and `devDependency` properties. If any packages are given in the `Package` property, only those packages will be installed and not any listed in the `package.json` file. The task will fail if `npm install` returns a non-zero exit code or if the expected path to the module does not exist after calling `npm install`.

    The `Package` property accepts a list of packages that should be installed. You may specify just the package name or the package name with a semantic version number, e.g. `rimraf: ^2.0.0`.

    You must specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed for you using NVM.

    You may additionally specify a version of NPM to use in the engines field of your package.json file. NPM will be downloaded into your package's 'node_modules' directory at the specified version. This local version of NPM will be used to execute all NPM tasks.

    # Properties

    # * `Package`: a list of NPM packages to install. List items can simply be package names, `rimraf`, or package names with semantic version numbers that NPM understands, e.g. `rimraf: ^2.0.0`. When using the `Package` property the task will only install the given packages and not the ones listed in the `package.json` file.
    # * `WorkingDirectory`: the directory where the `package.json` exists. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
    # * `NpmRegistryUri` (mandatory): the uri to set a custom npm registry.

    # Examples

    ## Example 1

        BuildTasks:
        - NpmInstall:
            NpmRegistryUri: "http://registry.npmjs.org"

    This example will install all the Node packages listed in the `package.json` file to the `BUILD_ROOT\node_modules` directory.

    ## Example 2

        BuildTasks:
        - NpmInstall:
            NpmRegistryUri: "http://registry.npmjs.org"
            Package:
            - gulp

    This example will install the Node package `gulp` to the `BUILD_ROOT\node_modules` directory.

    ## Example 3

        BuildTasks:
        - NpmInstall:
            NpmRegistryUri: "http://registry.npmjs.org"
            WorkingDirectory: app
            Package:
            - gulp
            - rimraf: ^2.0.0

    This example will install the Node packages `gulp` and the latest 2.x.x version of `rimraf` to the `BUILD_ROOT\app\node_modules` directory.
    #>

    [Whiskey.Task("NpmInstall", SupportsClean=$true, SupportsInitialize=$true)]
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
    if (-not $NpmRegistryUri)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''NpmRegistryUri'' is mandatory. It should be the URI to the registry from which Node.js packages should be downloaded, e.g.,

        BuildTasks:
        - NpmInstall:
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
        Write-Timing -Message 'Task Cleaning Complete'
        return
    }

    if ($TaskContext.ShouldInitialize())
    {
        Write-Timing -Message 'Initializing'
        Invoke-WhiskeyNpmCommand -InitializeOnly -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper

        if ($Global:LASTEXITCODE -ne 0)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Task initialization failed.'
        }

        Write-Timing -Message 'Task Initialization Complete'
        return
    }

    if (-not $TaskParameter['Package'])
    {
        Write-Timing -Message 'Installing Node modules'
        Invoke-WhiskeyNpmCommand -NpmCommand 'install' -Argument '--production=false' -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper

        if ($Global:LASTEXITCODE -ne 0)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Failed to install Node dependencies listed in ''{0}''.' -f (Join-Path -Path $workingDirectory -ChildPath 'package.json'))
        }

        Write-Timing -Message 'COMPLETE'
    }
    else
    {
        foreach ($package in $TaskParameter['Package'])
        {
            if ($package | Get-Member -Name 'Keys')
            {
                $packageName = $package.Keys | Select-Object -First 1
                $packageVersion = $package[$packageName]

                Write-Timing -Message ('Installing {0} at version {1}' -f $packageName,$packageVersion)
                $modulePath = Install-WhiskeyNodeModule -Name $packageName -Version $packageVersion -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper

                if (-not $modulePath)
                {
                    Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Node module ''{0}'' version ''{1}'' failed to install.' -f $packageName, $packageVersion)
                }

                Write-Timing -Message 'COMPLETE'
            }
            else
            {
                Write-Timing -Message ('Installing {0}' -f $package)
                $modulePath = Install-WhiskeyNodeModule -Name $package -ApplicationRoot $workingDirectory -RegistryUri $npmRegistryUri -ForDeveloper:$TaskContext.ByDeveloper

                if (-not $modulePath)
                {
                    Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Node module ''{0}'' failed to install.' -f $package)
                }

                Write-Timing -Message 'COMPLETE'
            }
        }
    }
}
