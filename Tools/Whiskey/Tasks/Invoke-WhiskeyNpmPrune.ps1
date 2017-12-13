
function Invoke-WhiskeyNpmPrune
{
    <#
    .SYNOPSIS
    Runs the `npm prune` command for a Node.js module.
    
    .DESCRIPTION
    The `NpmPrune` task runs the `npm prune` command to remove extraneous packages found in a Node.js project's `node_modules` directory.

    The task will remove all packages listed in `devDependencies` in the node module's `package.json` file as well as any packages found in the `node_modules` directory that aren't listed in `Dependencies` of the `package.json` file.
    
    By default, the task will run from your `whiskey.yml` file's directory (i.e. the build root). Change the working directory with the `WorkingDirectory` property (**must** be a relative path to your `whiskey.yml` file). The node module's `package.json' file **must** exist in the working directory.
    
    # Properties

    * `WorkingDirectory`: the directory from which to run the `npm prune` command, defaults to the build root. **Must** be a relative path to the `whiskey.yml` file and **must** contain the node module's `package.json` file.
    * `NpmRegistryUri`: the uri to an npm registry from which the `npm` module will be downloaded from if necessary.

    # Examples

    ## Example 1
        
        BuildTasks:
        - NpmPrune
    
    This example demonstrates running `npm prune` from the same directory as the build's `whiskey.yml` file. The node module's `package.json` file exists in the same directory as the `whiskey.yml` file.

    ## Example 2

        BuildTasks:
        - NpmPrune:
            WorkingDirectory: src\node-module-root

    This example demonstrates running `npm prune` from the `BUILD_ROOT\src\node-module-root` directory where the node module's `package.json` can be found.
    #>

    [Whiskey.Task("NpmPrune", SupportsInitialize=$true)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context the task is running under.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The parameters/configuration to use to run the task.
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $workingDirectory = $TaskContext.BuildRoot
    if ($TaskParameter['WorkingDirectory'])
    {
        $workingDirectory = $TaskParameter['WorkingDirectory'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'WorkingDirectory'
    }

    $npmRegistryUri = $TaskParameter['NpmRegistryUri']
    if (-not $npmRegistryUri) 
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''NpmRegistryUri'' is mandatory. It should be the URI to the registry from which the NPM module should be downloaded from if necessary. E.g.,
        
        BuildTasks:
        - NpmPrune:
            NpmRegistryUri: https://registry.npmjs.org/
        '
    }

    $packageJson = Join-Path -Path $workingDirectory -ChildPath 'package.json'
    If (-not (Test-Path -Path $packageJson -PathType 'Leaf'))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('''package.json'' file does not exist at ''{0}''. The ''NpmPrune'' task requires a Node.js ''package.json'' file to know which packages should be pruned.')
    }

    $nodePath = Install-WhiskeyNodeJs -RegistryUri $npmRegistryUri -ApplicationRoot $workingDirectory -ForDeveloper:$TaskContext.ByDeveloper

    if ( $TaskContext.ShouldInitialize() )
    {
        return
    }

    Push-Location $workingDirectory
    try
    {
        $npmPath = Get-WhiskeyNPMPath -NodePath $nodePath -ApplicationRoot $workingDirectory

        Invoke-Command -ScriptBlock {
            & $nodePath $npmPath prune --production
        }

        if ($LASTEXITCODE -ne 0)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NPM command ''npm prune'' failed with exit code ''{0}''.' -f $LASTEXITCODE)
        }
    }
    finally
    {
        Pop-Location
    }
}
