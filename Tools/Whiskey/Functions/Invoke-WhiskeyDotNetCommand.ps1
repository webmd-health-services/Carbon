
function Invoke-WhiskeyDotNetCommand
{
    <#
    .SYNOPSIS
    Runs `dotnet.exe` with a given SDK command and arguments.

    .DESCRIPTION
    The `Invoke-WhiskeyDotNetCommand` function runs the `dotnet.exe` executable with a given SDK command and any optional arguments. Pass the path to the `dotnet.exe` to the `DotNetPath` parameter. Pass the name of the SDK command to the `Name` parameter.

    You may pass a list of arguments to the `dotnet.exe` command with the `ArgumentList` parameter. By default, the `dotnet.exe` command runs with any solution or .csproj files found in the current directory. To run the `dotnet.exe` command with a specific solution or .csproj file pass the path to that file to the `ProjectPath` parameter.

    .EXAMPLE
    Invoke-WhiskeyDotNetCommand -TaskContext $TaskContext -DotNetPath 'C:\Program Files\dotnet\dotnet.exe' -Name 'build' -ArgumentList '--verbosity minimal','--no-incremental' -ProjectPath 'C:\Build\DotNetCore.csproj'

    Demonstrates running the following command `C:\> & "C:\Program Files\dotnet\dotnet.exe" build --verbosity minimal --no-incremental C:\Build\DotNetCore.csproj`
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The `Whiskey.Context` object for the task running the command.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the `dotnet.exe` executable to run the SDK command with.
        $DotNetPath,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the .NET Core SDK command to run.
        $Name,

        [string[]]
        # A list of arguments to pass to the .NET Core SDK command.
        $ArgumentList,

        [string]
        # The path to a .NET Core solution or project file to pass to the .NET Core SDK command.
        $ProjectPath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $dotNetExe = $DotNetPath | Resolve-Path -ErrorAction 'Ignore'
    if (-not $dotNetExe)
    {
        Write-Error -Message ('"{0}" does not exist.' -f $DotNetPath)
        return
    }

    $loggerArgs = & {
        '/filelogger9'
        $logFilePath = ('dotnet.{0}.log' -f $Name.ToLower())
        if( $ProjectPath )
        {
            $logFilePath = 'dotnet.{0}.{1}.log' -f $Name.ToLower(),($ProjectPath | Split-Path -Leaf)
        }
        $logFilePath = Join-Path -Path $TaskContext.OutputDirectory.FullName -ChildPath $logFilePath
        ('/flp9:LogFile={0};Verbosity=d' -f $logFilePath)
    }

    $commandInfoArgList = & {
        $Name
        $ArgumentList
        $loggerArgs
        $ProjectPath
    }

    Write-WhiskeyCommand -Context $TaskContext -Path $dotNetExe -ArgumentList $commandInfoArgList

    Invoke-Command -ScriptBlock {
        param(
            $DotNetExe,
            $Command,
            $DotNetArgs,
            $LoggerArgs,
            $Project
        )

        & $DotNetExe $Command $DotNetArgs $LoggerArgs $Project

    } -ArgumentList $dotNetExe,$Name,$ArgumentList,$loggerArgs,$ProjectPath

    if ($LASTEXITCODE -ne 0)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('dotnet.exe failed with exit code {0}' -f $LASTEXITCODE)
        return
    }
}
