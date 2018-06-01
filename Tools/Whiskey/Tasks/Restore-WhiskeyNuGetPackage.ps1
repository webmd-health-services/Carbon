
function Restore-WhiskeyNuGetPackage
{
    <#
    .SYNOPSIS
    Restores NuGet packages.

    .DESCRIPTION
    The `NuGetRestore` task restores NuGet packages. Set the `Path` property to the path to the solution file, packages.config file, Microsoft Build project, or a project.json file whose packages you want to restore.

    By default, `NuGetRestore` downloads and used the latest version of NuGet. Set the `Version` property to pin this task to a specific version of NuGet.

    You can pass custom arguments to NuGet.exe via the `Argument` property. Arguments are passed as-is. `Argument` should be an array of arguments.

    The NuGet executable doesn't report success or failure. If the NuGet restore fails, you'll see compilation errors instead of a problem with this task.

    # Example 1

    This demonstrates how to restore the NuGet packages for a Visual Studio solution.

        Build:
        - NuGetRestore:
            Path: MySolution.sln

    # Example 2

    This demonstrates how to pin the task to use a specific version of NuGet, in this case, `4.1.0`. Without the `Version` attribute, the latest version of NuGet is used.

        Build:
        -NuGetRestore:
            Path: MySolution.sln
            Version: 4.1.0

    # Example 3

    This demonstrates how to pass custom arguments to NuGet.exe with the `Argument` property. In this example, packages will be put in a `packages` directory in the build root (i.e. the same directory as your `whiskey.yml` file).

        Build:
        -NuGetRestore:
            Path: packages.config
            Argument:
            - "-PackagesDirectory"
            - $(WHISKEY_BUILD_ROOT)\packages


    #>
    [CmdletBinding()]
    [Whiskey.TaskAttribute("NuGetRestore")]
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

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'

    $nuGetPath = Install-WhiskeyNuGet -DownloadRoot $TaskContext.BuildRoot -Version $TaskParameter['Version']

    foreach( $item in $path )
    {
        & $nuGetPath 'restore' $item $TaskParameter['Argument']
    }
}
