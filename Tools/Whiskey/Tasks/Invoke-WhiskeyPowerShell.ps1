
function Invoke-WhiskeyPowerShell
{
    <#
    .SYNOPSIS
    Executes PowerShell tasks.

    .DESCRIPTION
    The PowerShell task runs PowerShell scripts. You specify the scripts to run via the `Path` property. Paths must be relative to the whiskey.yml file. Pass arguments to the scripts with the `Argument` property, which is a hash table of parameter names and values. PowerShell scripts are run in new, background processes.

    The PowerShell task runs your script in *all* build modes: during builds, during initialization, and during clean. If you want your script to only run in one mode, use the `OnlyDuring` property to specify the mode you want it to run in or the `ExceptDuring` property to specify the run mode you don't want it to run in.

    The PowerShell task will fail a build if the script it runs returns a non-zero exit code or sets the `$?` variable to `$false`.

    To receive the current build context as a parameter to your PowerShell script, add a `$TaskContext` parameter, e.g.

        param(
            [object]
            $TaskContext
        )

    This is *not* recommended.

    ## Properties
    * **Path** (mandatory): the paths to the PowerShell scripts to run. Paths must be relative to the  whiskey.yml file. Script arguments are not supported.
    * **Argument**: a hash table of name/value pairs that are passed to your script as arguments. The hash table is actually splatted when passed to your script.

    ## Examples

    ### Example 1

        Build:
        - PowerShell:
            Path: init.ps1
            Argument:
                Environment: "Dev"
                Verbose: true

    Demonstrates how to run a PowerShell script during your build. In this case, Whiskey will run `.\init.ps1 -Environment "Dev" -Verbose`.

    ### Example 2

        Build:
        - PowerShell:
            ExceptDuring: Clean
            Path: init.ps1
            Argument:
                Environment: "Dev"
                Verbose: true

    Demonstrates how to run a PowerShell script except when it is cleaning. If you have a script you want to use to initialize your build environment, it should run during the build and initialize modes. Set the `ExceptDuring` property to `Clean` to make that happen.

    ### Example 3

        Build:
        - PowerShell:
            OnlyDuring: Clean
            Path: clean.ps1

    Demonstrates how to run a PowerShell script only when running in clean mode. 
    #>
    [Whiskey.Task("PowerShell",SupportsClean=$true,SupportsInitialize=$true)]
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
    
    if( -not ($TaskParameter.ContainsKey('Path')) )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Path'' is mandatory. It should be one or more paths, which should be a list of PowerShell Scripts to run, e.g. 
        
        Build:
        - PowerShell:
            Path:
            - myscript.ps1
            - myotherscript.ps1
            WorkingDirectory: bin')
    }
    
    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'

    $workingDirectory = (Get-Location).ProviderPath

    $argument = $TaskParameter['Argument']
    if( -not $argument )
    {
        $argument = @{ }
    }

    $moduleRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    foreach( $scriptPath in $path )
    {

        if( -not (Test-Path -Path $WorkingDirectory -PathType Container) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Can''t run PowerShell script ''{0}'': working directory ''{1}'' doesn''t exist.' -f $scriptPath,$WorkingDirectory)
            continue
        }

        $scriptCommand = Get-Command -Name $scriptPath -ErrorAction Ignore
        if( -not $scriptCommand )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Can''t run PowerShell script ''{0}'': it has a syntax error.' -f $scriptPath)
            continue
        }

        $passTaskContext = $scriptCommand.Parameters.ContainsKey('TaskContext')

        if( (Get-Member -InputObject $argument -Name 'Keys') )
        {
            $scriptCommand.Parameters.Values | 
                Where-Object { $_.ParameterType -eq [switch] } | 
                Where-Object { $argument.ContainsKey($_.Name) } |
                ForEach-Object { $argument[$_.Name] = $argument[$_.Name] | ConvertFrom-WhiskeyYamlScalar }
        }

        $resultPath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('PowerShell-{0}-RunResult-{1}' -f ($scriptPath | Split-Path -Leaf),([IO.Path]::GetRandomFileName()))
        $job = Start-Job -ScriptBlock {
            $workingDirectory = $using:WorkingDirectory
            $scriptPath = $using:ScriptPath
            $argument = $using:argument
            $taskContext = $using:TaskContext
            $moduleRoot = $using:moduleRoot
            $resultPath = $using:resultPath
            $passTaskContext = $using:passTaskContext

            Invoke-Command -ScriptBlock { 
                                            $VerbosePreference = 'SilentlyContinue';
                                            & (Join-Path -Path $moduleRoot -ChildPath 'Import-Whiskey.ps1' -Resolve -ErrorAction Stop)
                                        }

            $VerbosePreference = $using:VerbosePreference

            $contextArgument = @{ }
            if( $passTaskContext )
            {
                $contextArgument['TaskContext'] = $taskContext
            }

            Set-Location $workingDirectory
            $Global:LASTEXITCODE = 0

            & $scriptPath @contextArgument @argument

            $result = @{
                'ExitCode'   = $Global:LASTEXITCODE
                'Successful' = $?
            }

            $result | ConvertTo-Json | Set-Content -Path $resultPath
        }

        do
        {
            $job | Receive-Job
        }
        while( -not ($job | Wait-Job -Timeout 1) )

        $job | Receive-Job

        if( (Test-Path -Path $resultPath -PathType Leaf) )
        {
            $runResult = Get-Content -Path $resultPath -Raw | ConvertFrom-Json
        }
        else
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('PowerShell script ''{0}'' threw a terminating exception.' -F $scriptPath)
        }

        if( $runResult.ExitCode -ne 0 )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('PowerShell script ''{0}'' failed, exited with code {1}.' -F $scriptPath,$runResult.ExitCode)
        }
        elseif( $runResult.Successful -eq $false )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('PowerShell script ''{0}'' threw a terminating exception.' -F $scriptPath)
        }

    }
}
