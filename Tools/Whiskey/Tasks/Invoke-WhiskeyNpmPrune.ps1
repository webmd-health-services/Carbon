
function Invoke-WhiskeyNpmPrune
{
    <#
    .SYNOPSIS
    Runs the `npm prune` command to remove all developer dependencies from an project's node_modules directory.
    
    .DESCRIPTION
    The `NpmPrune` task runs the `npm prune` command to remove extraneous packages found in a Node.js project's `node_modules` directory.

    The task will remove all packages listed in `devDependencies` in the node module's `package.json` file as well as any packages found in the `node_modules` directory that aren't listed in `Dependencies` of the `package.json` file.
    
    By default, the task will run from your `whiskey.yml` file's directory (i.e. the build root). Change the working directory with the `WorkingDirectory` property (**must** be a relative path to your `whiskey.yml` file). The project's `package.json' file **must** exist in the working directory.
    
    This task will install the latest LTS version of Node into a `.node` directory (in the same directory as your whiskey.yml file). To use a specific version, set the `engines.node` property in your package.json file to the version you want. (See https://docs.npmjs.com/files/package.json#engines for more information.)
    
    # Properties

    * `WorkingDirectory`: the directory from which to run the `npm prune` command, defaults to the build root. **Must** be a relative path to the `whiskey.yml` file and **must** contain the node module's `package.json` file.
    * `NodeVersion`: the version of Node to use. By default, the version in the `engines.node` property of your package.json file is used. If that is missing, the latest LTS version of Node is used. By default, the version of NPM that shipped with that version of Node is used. You can customize what version of NPM to use by setting the `engines.npm` property in your package.json file to the version you want.

    # Examples

    ## Example 1
        
        Build:
        - NpmPrune
    
    This example demonstrates running `npm prune` from the same directory as the build's `whiskey.yml` file. The node module's `package.json` file exists in the same directory as the `whiskey.yml` file.

    ## Example 2

        Build:
        - NpmPrune:
            WorkingDirectory: src\node-module-root

    This example demonstrates running `npm prune` from the `BUILD_ROOT\src\node-module-root` directory where the node module's `package.json` can be found.
    #>
    [Whiskey.Task('NpmPrune')]
    [Whiskey.RequiresTool('Node','NodePath',VersionParameterName='NodeVersion')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The context the task is running under.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The parameters/configuration to use to run the task.
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    Invoke-WhiskeyNpmCommand -Name 'prune' -ArgumentList '--production' -NodePath $TaskParameter['NodePath'] -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
}
