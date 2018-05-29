
function New-WhiskeyNuGetPackage
{
    [Whiskey.Task("NuGetPack")]
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
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Path'' is mandatory. It should be one or more paths to .csproj or .nuspec files to pack, e.g. 
            
    Build:
    - PublishNuGetPackage:
        Path:
        - MyProject.csproj
        - MyNuspec.nuspec
    ')
    }

    $paths = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'

    $symbols = $TaskParameter['Symbols'] | ConvertFrom-WhiskeyYamlScalar
    $symbolsArg = ''
    $symbolsFileNameSuffix = ''
    if( $symbols )
    {
        $symbolsArg = '-Symbols'
        $symbolsFileNameSuffix = '.symbols'
    }
       
    $nuGetPath = Install-WhiskeyNuGet -DownloadRoot $TaskContext.BuildRoot -Version $TaskParameter['Version']
    if( -not $nugetPath )
    {
        return
    }

    foreach ($path in $paths)
    {
        $projectName = [IO.Path]::GetFileNameWithoutExtension(($path | Split-Path -Leaf))
        $packageVersion = $TaskContext.Version.SemVer1
                    
        # Create NuGet package
        $configuration = Get-WhiskeyMSBuildConfiguration -Context $TaskContext

        & $nugetPath pack -Version $packageVersion -OutputDirectory $TaskContext.OutputDirectory $symbolsArg -Properties ('Configuration={0}' -f $configuration) $path

        # Make sure package was created.
        $filename = '{0}.{1}{2}.nupkg' -f $projectName,$packageVersion,$symbolsFileNameSuffix

        $packagePath = Join-Path -Path $TaskContext.OutputDirectory -childPath $filename
        if( -not (Test-Path -Path $packagePath -PathType Leaf) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('We ran nuget pack against ''{0}'' but the expected NuGet package ''{1}'' does not exist.' -f $path,$packagePath)
        }
    }
}
