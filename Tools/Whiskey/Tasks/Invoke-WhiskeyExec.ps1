function Invoke-WhiskeyExec
{
    [CmdletBinding()]
    [Whiskey.Task("Exec",SupportsClean=$true,SupportsInitialize=$true)]
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

    if( $TaskParameter.ContainsKey('') )
    {
        $regExMatches = Select-String -InputObject $TaskParameter[''] -Pattern '([^\s"'']+)|("[^"]*")|(''[^'']*'')' -AllMatches
        $defaultProperty = @($regExMatches.Matches.Groups | Where-Object { $_.Name -ne '0' -and $_.Success -eq $true } | Select-Object -ExpandProperty 'Value')

        $TaskParameter['Path'] = $defaultProperty[0]
        if( $defaultProperty.Count -gt 1 )
        {
            $TaskParameter['Argument'] = $defaultProperty[1..($defaultProperty.Count - 1)] | ForEach-Object { $_.Trim("'",'"') }
        }
    }

    $path = $TaskParameter['Path']
    if ( -not $path )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Path'' is mandatory. It should be the Path to the executable you want the Exec task to run, e.g.
        
            Build:
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

    Write-WhiskeyCommand -Context $TaskContext -Path $path -ArgumentList $TaskParameter['Argument']

    # Don't use Start-Process. If/when a build runs in a background job, when Start-Process finishes, it immediately terminates the build. Full stop.
    & $path $TaskParameter['Argument']
    $exitCode = $LASTEXITCODE
    
    $successExitCodes = $TaskParameter['SuccessExitCode']
    if( -not $successExitCodes )
    {
        $successExitCodes = '0'
    }

    foreach( $successExitCode in $successExitCodes )
    {
        if( $successExitCode -match '^(\d+)$' )
        {
            if( $exitCode -eq [int]$Matches[0] )
            {
                Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} = {1}' -f $exitCode,$Matches[0])
                return
            }
        }
        
        if( $successExitCode -match '^(<|<=|>=|>)\s*(\d+)$' )
        {
            $operator = $Matches[1]
            $successExitCode = [int]$Matches[2]
            switch( $operator )
            {
                '<'
                {
                    if( $exitCode -lt $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} < {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
                '<='
                {
                    if( $exitCode -le $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} <= {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
                '>'
                {
                    if( $exitCode -gt $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} > {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
                '>='
                {
                    if( $exitCode -ge $successExitCode )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} >= {1}' -f $exitCode,$successExitCode)
                        return
                    }
                }
            }
        }
        
        if( $successExitCode -match '^(\d+)\.\.(\d+)$' )
        {
            if( $exitCode -ge [int]$Matches[1] -and $exitCode -le [int]$Matches[2] )
            {
                Write-WhiskeyVerbose -Context $TaskContext -Message ('Exit Code {0} <= {1} <= {2}' -f $Matches[1],$exitCode,$Matches[2])
                return
            }
        }
    }
    
    Stop-WhiskeyTask -TaskContext $TaskContext -Message ('''{0}'' returned with an exit code of ''{1}''. View the build output to see why the executable''s process failed.' -F $TaskParameter['Path'],$exitCode)
}
