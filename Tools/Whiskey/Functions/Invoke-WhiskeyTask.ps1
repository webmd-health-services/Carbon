
function Invoke-WhiskeyTask
{
    <#
    .SYNOPSIS
    Runs a Whiskey task.
    
    .DESCRIPTION
    The `Invoke-WhiskeyTask` function runs a Whiskey task.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context this task is operating in. Use `New-WhiskeyContext` to create context objects.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the task.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [hashtable]
        # The parameters/configuration to use to run the task. 
        $Parameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    function Invoke-Event
    {
        param(
            $Prefix,
            $EventName,
            $Property
        )

        if( -not $events.ContainsKey($EventName) )
        {
            return
        }

        foreach( $commandName in $events[$EventName] )
        {
            Write-Verbose -Message $prefix
            Write-Verbose -Message ('{0}  [On{1}]  {2}' -f $prefix,$EventName,$commandName)
            $startedAt = Get-Date
            $result = 'FAILED'
            try
            {
                $TaskContext.Temp = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('Temp.{0}.On{1}.{2}' -f $Name,$EventName,[IO.Path]::GetRandomFileName())
                if( -not (Test-Path -Path $TaskContext.Temp -PathType Container) )
                {
                    New-Item -Path $TaskContext.Temp -ItemType 'Directory' -Force | Out-Null
                }
                & $commandName -TaskContext $TaskContext -TaskName $Name -TaskParameter $Property
                $result = 'COMPLETED'
            }
            finally
            {
                if( (Test-Path -Path $TaskContext.Temp -PathType Container) )
                {
                    Remove-Item -Path $TaskContext.Temp -Recurse -Force -ErrorAction Ignore
                }
                $endedAt = Get-Date
                $duration = $endedAt - $startedAt
                Write-Verbose ('{0}  {1}  {2} in {3}' -f $prefix,(' ' * ($EventName.Length + 4)),$result,$duration)
            }
        }
    }

    $knownTasks = Get-WhiskeyTask

    $task = $knownTasks | Where-Object { $_.Name -eq $Name }

    $errorPrefix = '{0}: {1}[{2}]: {3}: ' -f $TaskContext.ConfigurationPath,$TaskContext.PipelineName,$TaskContext.TaskIndex,$Name

    if( -not $task )
    {
        $knownTaskNames = $knownTasks | Select-Object -ExpandProperty 'Name' | Sort-Object
        throw ('{0}: {1}[{2}]: ''{3}'' task does not exist. Supported tasks are:{4} * {5}' -f $TaskContext.ConfigurationPath,$Name,$TaskContext.TaskIndex,$Name,[Environment]::NewLine,($knownTaskNames -join ('{0} * ' -f [Environment]::NewLine)))
    }

    function Merge-Parameter
    {
        param(
            [hashtable]
            $SourceParameter,

            [hashtable]
            $TargetParameter
        )

        foreach( $key in $SourceParameter.Keys )
        {
            $sourceValue = $SourceParameter[$key]
            if( $TargetParameter.ContainsKey($key) )
            {
                $targetValue = $TargetParameter[$key]
                if( $targetValue -is [hashtable] -and $sourceValue -is [hashtable] )
                {
                    Merge-Parameter -SourceParameter $sourceValue -TargetParameter $targetValue
                }
                continue
            }

            $TargetParameter[$key] = $sourceValue
        }
    }

    $TaskContext.TaskName = $Name

    #I feel like this is missing a piece, because the current way that Whiskey tasks are named, they will never be run by this logic.
    $prefix = '[{0}]' -f $Name

    $onlyDuring = $Parameter['OnlyDuring']
    $exceptDuring = $Parameter['ExceptDuring']

    if ($onlyDuring -and $exceptDuring)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Both ''OnlyDuring'' and ''ExceptDuring'' properties are used. These properties are mutually exclusive, i.e. you may only specify one or the other.'
    }
    elseif ($onlyDuring -and ($onlyDuring -notin @('Clean', 'Initialize')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''OnlyDuring'' has an invalid value: ''{0}''. Valid values are the run modes ''Clean'' or ''Initialize''.' -f $onlyDuring)
    }
    elseif ($exceptDuring -and ($exceptDuring -notin @('Clean', 'Initialize')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''ExceptDuring'' has an invalid value: ''{0}''. Valid values are the run modes ''Clean'' or ''Initialize''.' -f $exceptDuring)
    }

    if ($onlyDuring -and ($TaskContext.RunMode -ne $onlyDuring))
    {
        Write-Verbose -Message ('{0}  SKIPPED  OnlyDuring: {1} -- Current RunMode: {2}' -f $prefix,$onlyDuring,$TaskContext.RunMode)
        return
    }
    elseif ($exceptDuring -and ($TaskContext.RunMode -eq $exceptDuring))
    {
        Write-Verbose -Message ('{0}  SKIPPED  ExceptDuring: {1} -- Current RunMode: {2}' -f $prefix,$exceptDuring,$TaskContext.RunMode)
        return
    }
    
    if( $TaskContext.ShouldClean() -and -not $task.SupportsClean )
    {
        Write-Verbose -Message ('{0}  SKIPPED  SupportsClean: $false' -f $prefix)
        return
    }
    if( $TaskContext.ShouldInitialize() -and -not $task.SupportsInitialize )
    {
        Write-Verbose -Message ('{0}  SKIPPED  SupportsInitialize: $false' -f $prefix)
        return
    }

    $onlyBy = $Parameter['OnlyBy']
    if( $onlyBy )
    {
        switch( $onlyBy )
        {
            'Developer'
            {
                if( -not $TaskContext.ByDeveloper )
                {
                    Write-Verbose -Message ('{0}  SKIPPED  OnlyBy: {1}; ByBuildServer: {2}' -f $prefix,$onlyBy,$TaskContext.ByBuildServer)
                    return
                }
            }
            'BuildServer'
            {
                if( -not $TaskContext.ByBuildServer )
                {
                    Write-Verbose -Message ('{0}  SKIPPED  OnlyBy: {1}; ByDeveloper: {2}' -f $prefix,$onlyBy,$TaskContext.ByDeveloper)
                    return
                }
            }
            default
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''OnlyBy'' has an invalid value: ''{0}''. Valid values are ''Developer'' (to only run the task when the build is being run by a developer) or ''BuildServer'' (to only run the task when the build is being run by a build server).' -f $onlyBy)
            }
        }
    }
    
    $branch = $TaskContext.BuildMetadata.ScmBranch
    $executeTaskOnBranch = $true
    
    if( $Parameter['OnlyOnBranch'] -and $Parameter['ExceptOnBranch'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('This task defines both OnlyOnBranch and ExceptOnBranch properties. Only one of these can be used. Please remove one or both of these properties and re-run your build.')
    }
    
    if( $Parameter['OnlyOnBranch'] )
    {
        $executeTaskOnBranch =$false
        Write-Verbose -Message ('OnlyOnBranch')
        foreach( $wildcard in $Parameter['OnlyOnBranch'] )
        {
            if( $branch -like $wildcard )
            {
                Write-Verbose -Message ('               {0}     -like  {1}' -f $branch, $wildcard)
                $executeTaskOnBranch = $true
                break
            }
            else
            {
                Write-Verbose -Message ('               {0}  -notlike  {1}' -f $branch, $wildcard)
            }
        }
    }

    if( $Parameter['ExceptOnBranch'] )
    {
        Write-Verbose -Message ('ExceptOnBranch')
        foreach( $wildcard in $Parameter['ExceptOnBranch'] )
        {
            if( $branch -like $wildcard )
            {
                Write-Verbose -Message ('               {0}     -like  {1}' -f $branch, $wildcard)
                $executeTaskOnBranch = $false
                break
            }
            else
            {
                Write-Verbose -Message ('               {0}  -notlike  {1}' -f $branch, $wildcard)
            }
        }
    }
    
    if( !$executeTaskOnBranch )
    {
        Write-Verbose -Message ('{0}  SKIPPED  {1} not configured to execute this task.' -f $prefix, $branch)
        return
    }

    $taskProperties = $Parameter.Clone()
    foreach( $commonPropertyName in @( 'OnlyBy', 'ExceptBy', 'OnlyOnBranch', 'ExceptOnBranch', 'OnlyDuring', 'ExceptDuring' ) )
    {
        $taskProperties.Remove($commonPropertyName)
    }
    
    if( $TaskContext.TaskDefaults.ContainsKey( $Name ) )
    {
        Merge-Parameter -SourceParameter $TaskContext.TaskDefaults[$Name] -TargetParameter $taskProperties
    }

    Resolve-WhiskeyVariable -Context $TaskContext -InputObject $taskProperties | Out-Null

    Invoke-Event -EventName 'BeforeTask' -Prefix $prefix -Property $taskProperties
    Invoke-Event -EventName ('Before{0}Task' -f $Name) -Prefix $prefix -Property $taskProperties

    Write-Verbose -Message $prefix
    $startedAt = Get-Date
    $result = 'FAILED'
    try
    {
        $TaskContext.Temp = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('Temp.{0}.{1}' -f $Name,[IO.Path]::GetRandomFileName())
        if( -not (Test-Path -Path $TaskContext.Temp -PathType Container) )
        {
            New-Item -Path $TaskContext.Temp -ItemType 'Directory' -Force | Out-Null
        }
        & $task.CommandName -TaskContext $TaskContext -TaskParameter $taskProperties
        $result = 'COMPLETED'
    }
    finally
    {
        if( (Test-Path -Path $TaskContext.Temp -PathType Container) )
        {
            Remove-Item -Path $TaskContext.Temp -Recurse -Force -ErrorAction Ignore
        }
        $endedAt = Get-Date
        $duration = $endedAt - $startedAt
        Write-Verbose ('{0}  {1} in {2}' -f $prefix,$result,$duration)
    }

    Invoke-Event -Prefix $prefix -EventName 'AfterTask' -Property $taskProperties
    Invoke-Event -Prefix $prefix -EventName ('After{0}Task' -f $Name) -Property $taskProperties
    Write-Verbose ($prefix)
    Write-Verbose ''
}