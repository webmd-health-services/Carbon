
function Invoke-WhiskeyPowerShell
{
    [Whiskey.Task("PowerShell")]
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
    
    if( -not ($TaskParameter.ContainsKey('Path')))
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should be one or more paths, which should be a list of PowerShell Scripts to run, e.g. 
        
            BuildTasks:
            - PowerShell:
                Path:
                - myscript.ps1
                - myotherscript.ps1
                WorkingDirectory: bin')
        }
    
    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'

    if( $TaskParameter.ContainsKey('WorkingDirectory') )
    {
        if( -not [IO.Path]::IsPathRooted($TaskParameter['WorkingDirectory']))
        {
            $workingDirectory = $TaskParameter['WorkingDirectory'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'WorkingDirectory'
        } 
        else
        {
            $workingDirectory = $TaskParameter['WorkingDirectory']
        }       
    }
    else
    {
        $WorkingDirectory = $TaskContext.BuildRoot
    }

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

        $resultPath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('PowerShell-{0}-ExitCode-{1}' -f ($scriptPath | Split-Path -Leaf),([IO.Path]::GetRandomFileName()))
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
                                            Import-Module -Name $moduleRoot
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
            $Global:LASTEXITCODE | Set-Content -Path $resultPath
        }

        do
        {
            $job | Receive-Job
        }
        while( -not ($job | Wait-Job -Timeout 1) )

        $job | Receive-Job

        if( -not (Test-Path -Path $resultPath -PathType Leaf) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('PowerShell script ''{0}'' threw a terminating exception.' -F $scriptPath)
        }
                    
        [int]$exitCode = Get-Content -Path $resultPath | Select-Object -First 1
        
        if( $exitCode )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('PowerShell script ''{0}'' failed, exited with code {1}.' -F $scriptPath,$exitCode)
        }

    }
}
