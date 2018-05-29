
function Invoke-WhiskeyParallelTask
{
    [CmdletBinding()]
    [Whiskey.Task('Parallel')]
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
    
    $queues = $TaskParameter['Queues']
    if( -not $queues )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property "Queues" is mandatory. It should be an array of queues to run. Each queue should contain a "Tasks" property that is an array of task to run, e.g.
 
    Build:
    - Parallel:
        Queues:
        - Tasks:
            - TaskOne
            - TaskTwo
        - Tasks:
            - TaskOne
 
'
    }
    
    try
    {
        $jobs = New-Object 'Collections.ArrayList'
        $queueIdx = -1

        foreach( $queue in $queues )
        {
            $queueIdx++
            $whiskeyModulePath = Join-Path -Path $PSScriptRoot -ChildPath '..\Whiskey.psd1' -Resolve

            if( -not $queue.ContainsKey('Tasks') )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Queue[{0}]: Property "Tasks" is mandatory. Each queue should have a "Tasks" property that is an array of Whiskey task to run, e.g.
 
    Build:
    - Parallel:
        Queues:
        - Tasks:
            - TaskOne
            - TaskTwo
        - Tasks:
            - TaskOne
 
    ' -f $queueIdx);
            }

            Write-WhiskeyVerbose -Context $TaskContext -Message ('[{0}]  Starting background queue.' -f $queueIdx)

            $job = Start-Job -Name $queueIdx -ScriptBlock {

                    Set-StrictMode -Version 'Latest'

                    function Sync-ObjectProperty
                    {
                        param(
                            [Parameter(Mandatory=$true)]
                            [object]
                            $Source,

                            [Parameter(Mandatory=$true)]
                            [object]
                            $Destination,

                            [string[]]
                            $ExcludeProperty
                        )

                        $Destination.GetType().DeclaredProperties | 
                            Where-Object { $ExcludeProperty -notcontains $_.Name } |
                            Where-Object { $_.GetSetMethod($false) } |
                            Select-Object -ExpandProperty 'Name' |
                            ForEach-Object { Write-Debug ('{0}  {1} -> {2}' -f $_,$Destination.$_,$Source.$_) ; $Destination.$_ = $Source.$_ }

                        Write-Debug ('Source      -eq $null  ?  {0}' -f ($Source -eq $null))
                        if( $Source -ne $null )
                        {
                            Write-Debug -Message 'Source'
                            Get-Member -InputObject $Source | Out-String | Write-Debug
                        }

                        Write-Debug ('Destination -eq $null  ?  {0}' -f ($Destination -eq $null))
                        if( $Destination -ne $null )
                        {
                            Write-Debug -Message 'Destination'
                            Get-Member -InputObject $Destination | Out-String | Write-Debug
                        }

                        Get-Member -InputObject $Destination -MemberType Property |
                            Where-Object { $ExcludeProperty -notcontains $_.Name } |
                            Where-Object { 
                                $name = $_.Name
                                if( -not $name )
                                {
                                    return
                                }

                                $value = $Destination.$name
                                if( $value -eq $null )
                                {
                                    return
                                }

                                Write-Debug ('Destination.{0,-20} -eq $null  ?  {1}' -f $name,($value -eq $null))
                                Write-Debug ('           .{0,-20} is            {1}' -f $name,$value.GetType())
                                return Get-Member -InputObject $value -Name 'Keys'
                            } |
                            ForEach-Object {
                                $propertyName = $_.Name
                                Write-Debug -Message ('{0}.{1} -> {2}.{1}' -f $Source.GetType(),$propertyName,$Destination.GetType())
                                $keys = $source.$propertyName.Keys
                                foreach( $key in $keys )
                                {
                                    $value = $source.$propertyName[$key]
                                    Write-Debug ('    [{0,-20}] -> {1}' -f $key,$value)
                                    $Destination.$propertyName[$key] = $source.$propertyName[$key]
                                }
                            }
                    }

                    $VerbosePreference = $using:VerbosePreference
                    $DebugPreferece = $using:DebugPreference
                    $whiskeyModulePath = $using:whiskeyModulePath 
                    $originalContext = $using:TaskContext

                    Import-Module -Name $whiskeyModulePath
                    $moduleRoot = $whiskeyModulePath | Split-Path

                    . (Join-Path -Path $moduleRoot -ChildPath 'Functions\Use-CallerPreference.ps1' -Resolve)
                    . (Join-Path -Path $moduleRoot -ChildPath 'Functions\New-WhiskeyContextObject.ps1' -Resolve)
                    . (Join-Path -Path $moduleRoot -ChildPath 'Functions\New-WhiskeyBuildMetadataObject.ps1' -Resolve)
                    . (Join-Path -Path $moduleRoot -ChildPath 'Functions\New-WhiskeyVersionObject.ps1' -Resolve)
                    . (Join-Path -Path $moduleRoot -ChildPath 'Functions\ConvertTo-WhiskeyTask.ps1' -Resolve)

                    # The task context gets serialized/deserialized into this new job process. We need to
                    # correctly deserialize it back to an actual `Whiskey.Context` object. 
                    $buildInfo = New-WhiskeyBuildMetadataObject
                    Sync-ObjectProperty -Source $originalContext.BuildMetadata -Destination $buildInfo -Exclude @( 'BuildServer' )
                    if( $originalContext.BuildMetadata.BuildServer )
                    {
                        $buildInfo.BuildServer = $originalContext.BuildMetadata.BuildServer
                    }
                
                    $buildVersion = New-WhiskeyVersionObject
                    Sync-ObjectProperty -Source $originalContext.Version -Destination $buildVersion -ExcludeProperty @( 'SemVer1', 'SemVer2', 'SemVer2NoBuildMetadata' )
                    $buildVersion.SemVer1 = $originalContext.Version.SemVer1.ToString()
                    $buildVersion.SemVer2 = $originalContext.Version.SemVer2.ToString()
                    $buildVersion.SemVer2NoBuildMetadata = $originalContext.Version.SemVer2NoBuildMetadata.ToString()

                    $context = New-WhiskeyContextObject
                    Sync-ObjectProperty -Source $originalContext -Destination $context -ExcludeProperty @( 'BuildMetadata', 'Configuration', 'Version' )

                    $context.BuildMetadata = $buildInfo
                    $context.Version = $buildVersion

                    $context.Variables | ConvertTo-Json -Depth 50 | Write-Debug
                    $context.ApiKeys | ConvertTo-Json -Depth 50 | Write-Debug
                    $context.Credentials | ConvertTo-Json -Depth 50 | Write-Debug
                    $context.TaskDefaults | ConvertTo-Json -Depth 50 | Write-Debug

                    $tasks = $using:queue['Tasks']
                    foreach( $task in $tasks )
                    {
                        $taskName,$taskParameter = ConvertTo-WhiskeyTask -InputObject $task -ErrorAction Stop
                        Invoke-WhiskeyTask -TaskContext $context -Name $taskName -Parameter $taskParameter
                    }
                }
                $job | 
                    Add-Member -MemberType NoteProperty -Name 'QueueIndex' -Value $queueIdx -PassThru |
                    Add-Member -MemberType NoteProperty -Name 'Completed' -Value $false
                [void]$jobs.Add($job)
        }

        $lastNotice = (Get-Date).AddSeconds(-61)
        while( $jobs | Where-Object { -not $_.Completed } )
        {
            foreach( $job in $jobs )
            {
                if( $job.Completed )
                {
                    continue
                }

                if( $lastNotice -lt (Get-Date).AddSeconds(-60) )
                {
                    Write-WhiskeyVerbose -Context $TaskContext -Message ('[{0}][{1}]  Waiting for queue.' -f $job.QueueIndex,$job.Name)
                    $notified = $true
                }

                $completedJob = $job | Wait-Job -Timeout 1
                if( $completedJob )
                {
                    $job.Completed = $true
                    $completedJob | Receive-Job
                    $duration = $job.PSEndTime - $job.PSBeginTime
                    Write-WhiskeyVerbose -Context $TaskContext -Message ('[{0}][{1}]  {2} in {3}' -f $job.QueueIndex,$job.Name,$job.State.ToString().ToUpperInvariant(),$duration)
                    if( $job.JobStateInfo.State -eq [Management.Automation.JobState]::Failed )
                    {
                        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Queue[{0}] failed. See previous output for error information.' -f $job.Name)
                    }
                }
            }

            if( $notified )
            {
                $notified = $false
                $lastNotice = Get-Date
            }
        }
    }
    finally
    {
        $jobs | Stop-Job 
        $jobs | Remove-Job
    }
}