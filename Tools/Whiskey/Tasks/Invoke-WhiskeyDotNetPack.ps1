
function Invoke-WhiskeyDotNetPack
{
    [CmdletBinding()]
    [Whiskey.Task("DotNetPack")]
    [Whiskey.RequiresTool('DotNet','DotNetPath',VersionParameterName='SdkVersion')]
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

    Write-Warning -Message ('The "DotNetTest" task is obsolete and will be removed in a future version of Whiskey. Please use the "DotNet" task instead.')

    $dotnetExe = $TaskParameter['DotNetPath']

    $projectPaths = ''
    if ($TaskParameter['Path'])
    {
        $projectPaths = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
    }

    $symbols = $TaskParameter['Symbols'] | ConvertFrom-WhiskeyYamlScalar

    $verbosity = $TaskParameter['Verbosity']
    if (-not $verbosity)
    {
        $verbosity = 'minimal'
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
        Invoke-WhiskeyDotNetCommand -TaskContext $TaskContext -DotNetPath $dotnetExe -Name 'pack' -ArgumentList $dotnetArgs -ProjectPath $project
    }
}
