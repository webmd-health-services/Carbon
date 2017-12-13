function Invoke-WhiskeyExec
{
    <#
    .SYNOPSIS
    Runs an executable.
    
    .DESCRIPTION
    The `Exec` task runs an executable. Specify the path to the executable to run with the task's `Path` property. The `Path` can be the name of an executable that can be found in the `PATH` environment variable, a path relative to your `whiskey.yml` file's directory, or an absolute path.

    The task will fail if the executable returns a non-zero exit code. Use the `SuccessExitCode` property to configure the task to interpret other exit codes as "success". 

    Pass arguments to the executable via the `Argument` property. The `Exec` task uses PowerShell's `Start-Process` cmdlet to run the executable, so that arguments will be passes as-is, with no escaping. YAML strings, however, are usually single-quoted (e.g. `'Value'`) or double-quoted (e.g. `"Value"`). If you're using a single quoted string and need to insert a single quote, escape it by using two single quotes, e.g. `'escape: '''` is converted to `escape '`. If you're using a double-quoted string and need to insert a double quote, escape it with `\`, e.g. `"escape: \""` is converted to `escape: "`. YAML supports other escape sequences in double-quoted strings. The full list of escape sequences is in the [YAML specification](http://yaml.org/spec/current.html#escaping in double quoted style/).

    By default, the executable is run from your `whiskey.yml` file's directory (i.e. the build root). Change the working directory with the `WorkingDirectory` property.

    # Properties

    * `Path` (*mandatory*): the path to the executable to run. This can be the name of an executable if it is in your PATH environment variable, a path relative to the `whiskey.yml` file, or an absolute path.
    * `Argument`: a list of arguments to pass to the executable. Read the documentation above for notes on how to properly escape arguments.
    * `WorkingDirectory`: the directory the executable will run in/from. By default, this is the build root, i.e. the `whiskey.yml` file's directory.
    * `SuccessExitCode`: a list of exit codes that the `Exec` task should interpret to mean the executable's process exited successfully. The default is `0`.

    # Examples

    ## Example 1

            BuildTasks:
            - Exec:
                Path: cmd.exe
                Argument:
                - /C
                - dir C:\

    This example demonstrates how to call an executable whose arguments have to be quoted a specific way. In this case, we're using `cmd.exe` to get a directory listing of the `C:\` directory. This example will run `cmd.exe /C dir C:\.

    ## Example 2

            BuildTasks:
            - Exec:
                Path: robocopy.exe
                Argument:
                - C:\Source
                - C:\Desitination
                - /MIR    
                SuccessExitCode:
                - 0
                - 1
                - 2
                - 3
                - 4
                - 5
                - 6
                - 7

    This example demonstrates how to configure the `Exec` task to fail when an executable can return multiple success exit codes. In this case, `robocopy.exe` can return any value less than 8 to report a successful copy.
    #>      

    [CmdletBinding()]
    [Whiskey.Task("Exec")]
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

    $path = $TaskParameter['Path']
    if ( -not $path )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Path'' is mandatory. It should be the Path to the executable you want the Exec task to run, e.g.
        
            BuildTasks:
            - Exec:
                Path: cmd.exe
            
        ')
    }

    if ( -not [IO.Path]::IsPathRooted($path) )
    {
        $path = Join-Path -Path $TaskContext.BuildRoot -ChildPath $path
    }
    
    if ( (Test-Path -Path $path -PathType Leaf) )
    {
        $path = $path | Resolve-Path | Select-Object -ExpandProperty 'ProviderPath'
    }
    else
    {
        $path = $TaskParameter['Path']
        if( -not (Get-Command -Name $path -CommandType Application -ErrorAction Ignore) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Executable ''{0}'' does not exist. We checked if the executable is at that path on the file system and if it is in your PATH environment variable.' -f $path)
        }
    }


    $workingDirectory = $TaskContext.BuildRoot
    if ( $TaskParameter['WorkingDirectory'] )
    {
        $workingDirectory = $TaskParameter['WorkingDirectory']

        if ( -not (Test-Path -Path $workingDirectory -PathType Container) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Could not locate the directory ''{0}'' specified in the ''WorkingDirectory'' property.' -f $workingDirectory)
        }
    }


    $argumentListParam = @{}
    if ( $TaskParameter['Argument'] )
    {
        $argumentListParam['ArgumentList'] = $TaskParameter['Argument']
    }


    $successExitCode = 0
    if ( $TaskParameter['SuccessExitCode'] )
    {
        $successExitCode = $TaskParameter['SuccessExitCode']
    }


    $process = Start-Process -FilePath $path @argumentListParam -WorkingDirectory $workingDirectory -NoNewWindow -Wait -PassThru

    $exitCode = $process.ExitCode
    if ( $exitCode -notin $successExitCode )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('''{0}'' returned with an exit code of ''{1}'', which is not one of the expected ''SuccessExitCode'' of ''{2}''. View the build output to see why the executable''s process failed.' -F $TaskParameter['Path'],$exitCode,$successExitCode -join ',')
    }

}