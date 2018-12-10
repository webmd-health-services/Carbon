
function Invoke-WhiskeyDotNet
{
    [CmdletBinding()]
    [Whiskey.Task("DotNet")]
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

    $command = $TaskParameter['Command']
    if( -not $command )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property "Command" is required. It should be the name of the dotnet.exe command to run, e.g. "build", "test", etc.')
        return
    }

    $dotnetExe = $TaskParameter['DotNetPath']

    $invokeParameters = @{
        TaskContext = $TaskContext
        DotNetPath = $dotnetExe
        Name = $command
        ArgumentList = $TaskParameter['Argument']
    }

    Write-WhiskeyVerbose -Context $TaskContext -Message ('.NET Core SDK {0}' -f (& $dotnetExe --version))

    if( $TaskParameter.ContainsKey('Path') )
    {
        $projectPaths = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
        foreach( $projectPath in $projectPaths )
        {
            Invoke-WhiskeyDotNetCommand @invokeParameters -ProjectPath $projectPath
        }
    }
    else
    {
        Invoke-WhiskeyDotNetCommand @invokeParameters
    }
}
