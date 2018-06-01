
function Invoke-WhiskeyNpmRunScript
{
    <#
    .SYNOPSIS
    Runs NPM scripts.
    
    .DESCRIPTION
    The `NpmRunScript` task will use NPM's `run` command to run a list of NPM scripts. These scripts are defined in your `package.json` file's `Script` property. The task will run all `Script` that were given to the task. If any script fails, the task will fail. A script failure is determined by examining the exit code of the `npm run` command, any non-zero exit code is considered a failure.

    You must specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed for you using NVM. 

    You may additionally specify a version of NPM to use in the engines field of your package.json file. NPM will be downloaded into your package's 'node_modules' directory at the specified version. This local version of NPM will be used to execute the list of `Script`.

    # Properties

    * `Script` (*mandatory*): a list of one or more NPM scripts to run, e.g. `npm run $SCRIPT_NAME`. Each script is run independently.
    * `WorkingDirectory`: the directory where the `package.json` exists. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
    * `NodeVersion`: the version of Node to use. By default, the version in the `engines.node` property of your package.json file is used. If that is missing, the latest LTS version of Node is used. By default, the version of NPM that shipped with that version of Node is used. You can customize what version of NPM to use by setting the `engines.npm` property in your package.json file to the version you want.

    # Examples

    ## Example 1

        Build:
        - NpmRunScript:
            Script:
            - build
            - test
    
    This example will run the `build` and `test` NPM scripts. The Node.js `package.json` file is located in the build root next to the `whiskey.yml` file.

    ## Example 2

        Build:
        - NpmRunScript:
            Script:
            - test
            WorkingDirectory: app
    
    This example will run the `test` NPM script. The root of the Node.js package and `package.json` file are located in the `(BUILD_ROOT)\app` directory.
    #>
    [Whiskey.Task('NpmRunScript')]
    [Whiskey.RequiresTool('Node','NodePath',VersionParameterName='NodeVersion')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $npmScripts = $TaskParameter['Script']
    if (-not $npmScripts)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''Script'' is mandatory. It should be a list of one or more npm scripts to run during your build, e.g.,

        Build:
        - NpmRunScript:
            Script:
            - build
            - test

        '
    }

    foreach ($script in $npmScripts)
    {
        Write-WhiskeyTiming -Message ('Running script ''{0}''.' -f $script)
        Invoke-WhiskeyNpmCommand -Name 'run-script' -ArgumentList $script -NodePath $TaskParameter['NodePath'] -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
        Write-WhiskeyTiming -Message ('COMPLETE')
    }
}
