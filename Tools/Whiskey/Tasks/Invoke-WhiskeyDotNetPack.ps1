
function Invoke-WhiskeyDotNetPack
{
    [CmdletBinding()]
    [Whiskey.Task("DotNetPack")]
    [Whiskey.RequiresTool('DotNet','DotNetPath',VersionParameterName='SdkVersion')]
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

    $dotnetExe = $TaskParameter['DotNetPath']

    $projectPaths = ''
    if ($TaskParameter['Path'])
    {
        $projectPaths = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    }

    $symbols = $TaskParameter['Symbols'] | ConvertFrom-WhiskeyYamlScalar

    $verbosity = $TaskParameter['Verbosity']
    if (-not $verbosity -and $TaskContext.ByBuildServer)
    {
        $verbosity = 'detailed'
    }

    $dotnetArgs = & {
        '-p:PackageVersion={0}' -f $TaskContext.Version.SemVer1.ToString()
        '--configuration={0}' -f (Get-WhiskeyMSBuildConfiguration -Context $TaskContext)
        '--output={0}' -f $TaskContext.OutputDirectory
        '--no-build'
        '--no-dependencies'
        '--no-restore'

        if ($symbols)
        {
            '--include-symbols'
        }

        if ($verbosity)
        {
            '--verbosity={0}' -f $verbosity
        }

        if ($TaskParameter['Argument'])
        {
            $TaskParameter['Argument']
        }
    }

    Write-WhiskeyVerbose -Context $TaskContext -Message ('.NET Core SDK {0}' -f (& $dotnetExe --version))

    foreach($project in $projectPaths)
    {
        $fullArgumentList = & {
            'pack'
            $dotnetArgs
            $project
        }

        Write-WhiskeyCommand -Context $TaskContext -Path $dotnetExe -ArgumentList $fullArgumentList

        & $dotnetExe pack $dotnetArgs $project

        if ($LASTEXITCODE -ne 0)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('dotnet.exe failed with exit code ''{0}''' -f $LASTEXITCODE)
        }
    }
}
