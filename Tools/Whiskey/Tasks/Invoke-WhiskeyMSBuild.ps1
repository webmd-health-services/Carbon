function Invoke-WhiskeyMSBuild
{
    <#
    .SYNOPSIS
    Invoke-WhiskeyMSBuild builds .NET projects with MSBuild

    .DESCRIPTION
    The MSBuild task is used to build .NET projects with MSBuild from the version of .NET 4 that is installed. Items are built by running the `clean` and `build` target against each file. The TaskParameter should contain a `Path` element that is a list of projects, solutions, or other files to build.  
    
    The build fails if any MSBuild target fails. If your `whiskey.yml` file defines a `Version` element and the build is running under a build server, all AssemblyInfo.cs files under each path is updated with appropriate `AssemblyVersion`, `AssemblyFileVersion`, and `AssemblyInformationalVersion` attributes. The `AssemblyInformationalVersion` attribute will contain the full semantic version from `whiskey.yml` plus some build metadata: the build server's build number, the Git branch, and the Git commit ID.

    You *must* include paths to build with the `Path` parameter.

    .EXAMPLE
    Invoke-WhiskeyMSBuild -TaskContext $TaskContext -TaskParameter $TaskParameter

    Demonstrates how to call the `WhiskeyMSBuildTask`. In this case each path in the `Path` element in $TaskParameter relative to your whiskey.yml file, will be built with MSBuild.exe given the build configuration contained in $TaskContext.

    #>
    [Whiskey.Task("MSBuild",SupportsClean=$true)]
    [CmdletBinding()]
    param(
        [object]
        # The context this task is operating in. Use `New-WhiskeyContext` to create context objects.
        $TaskContext,
        
        [hashtable]
        # The parameters/configuration to use to run the task. Should be a hashtable that contains the following item(s):
        # 
        # * `Path` (Mandatory): the relative paths to the files/directories to include in the build. Paths should be relative to the whiskey.yml file they were taken from.
        $TaskParameter
    )

    Set-StrictMode -version 'Latest'  
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    #setup
    $nuGetPath = Install-WhiskeyNuGet -DownloadRoot $TaskContext.BuildRoot -Version $TaskParameter['NuGetVersion']
    
    # Make sure the Taskpath contains a Path parameter.
    if( -not ($TaskParameter.ContainsKey('Path')) -or -not $TaskParameter['Path'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should be one or more paths, relative to your whiskey.yml file, to build with MSBuild.exe, e.g. 
        
        BuildTasks:
        - MSBuild:
            Path:
            - MySolution.sln
            - MyCsproj.csproj')
    }
    
    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'

    $msbuildInfos = Get-MSBuild | Sort-Object -Descending 'Version'
    $version = $TaskParameter['Version']
    if( $version )
    {
        $msbuildInfo = $msbuildInfos | Where-Object { $_.Name -eq $version }
    }
    else
    {
        $msbuildInfo = $msbuildInfos | Select-Object -First 1
    }

    if( -not $msbuildInfo )
    {
        $msbuildVersionNumbers = $msbuildInfos | Select-Object -ExpandProperty 'Name'
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('MSBuild {0} is not installed. Installed versions are: {1}' -f $version,($msbuildVersionNumbers -join ', '))
    }

    $msbuildExePath = $msbuildInfo.Path
    Write-Verbose -Message ('{0}' -f $msbuildExePath)
    
    $target = @( 'build' )
    if( $TaskContext.ShouldClean() )
    {
        $target = 'clean'
    }
    else
    {
        if( $TaskParameter.ContainsKey('Target') )
        {
            $target = $TaskParameter['Target']
        }
    }

    foreach( $projectPath in $path )
    {
        Write-Verbose -Message ('  {0}' -f $projectPath)
        $errors = $null
        if( $projectPath -like '*.sln' )
        {
            if( $TaskContext.ShouldClean() )
            {
                $packageDirectoryPath = Join-Path -path ( Split-Path -Path $projectPath -Parent ) -ChildPath 'packages'
                if( Test-Path -Path $packageDirectoryPath -PathType Container )
                {
                    Write-Verbose -Message ('  Removing NuGet packages at {0}.' -f $packageDirectoryPath)
                    Remove-Item $packageDirectoryPath -Recurse -Force
                }
            }
            else
            {
                Write-Verbose -Message ('  Restoring NuGet packages.')
                & $nugetPath restore $projectPath
            }
        }

        if( $TaskContext.ByBuildServer )
        {
            $projectPath | 
                Split-Path | 
                Get-ChildItem -Filter 'AssemblyInfo.cs' -Recurse | 
                ForEach-Object {
                    $assemblyInfo = $_
                    $assemblyInfoPath = $assemblyInfo.FullName
                    $newContent = Get-Content -Path $assemblyInfoPath | Where-Object { $_ -notmatch '\bAssembly(File|Informational)?Version\b' }
                    $newContent | Set-Content -Path $assemblyInfoPath
                    Write-Verbose -Message ('    Updating version in {0}.' -f $assemblyInfoPath)
    @"
[assembly: System.Reflection.AssemblyVersion("{0}")]
[assembly: System.Reflection.AssemblyFileVersion("{0}")]
[assembly: System.Reflection.AssemblyInformationalVersion("{1}")]
"@ -f $TaskContext.Version.Version,$TaskContext.Version.SemVer2 | Add-Content -Path $assemblyInfoPath
                }
        }

        $verbosity = 'm'
        if( $TaskParameter['Verbosity'] )
        {
            $verbosity = $TaskParameter['Verbosity']
        }

        $configuration = Get-WhiskeyMSBuildConfiguration -Context $TaskContext

        $property = Invoke-Command {
                                        ('Configuration={0}' -f $configuration)

                                        if( $TaskParameter.ContainsKey('Property') )
                                        {
                                            $TaskParameter['Property']
                                        }

                                        if( $TaskParameter.ContainsKey('OutputDirectory') )
                                        {
                                            ('OutDir={0}' -f ($TaskParameter['OutputDirectory'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'OutputDirectory' -Force))
                                        }
                                  }

        $cpuArg = '/maxcpucount'
        $cpuCount = $TaskParameter['CpuCount'] | ConvertFrom-WhiskeyYamlScalar
        if( $cpuCount )
        {
            $cpuArg = '/maxcpucount:{0}' -f $TaskParameter['CpuCount']
        }

        if( ($TaskParameter['NoMaxCpuCountArgument'] | ConvertFrom-WhiskeyYamlScalar) )
        {
            $cpuArg = ''
        }

        $noFileLogger = $TaskParameter['NoFileLogger'] | ConvertFrom-WhiskeyYamlScalar

        $projectFileName = $projectPath | Split-Path -Leaf
        $logFilePath = Join-Path -Path $TaskContext.OutputDirectory -ChildPath ('msbuild.{0}.debug.log' -f $projectFileName)
        $msbuildArgs = Invoke-Command {
                                            ('/verbosity:{0}' -f $verbosity)
                                            $cpuArg
                                            $TaskParameter['Argument']
                                            if( -not $noFileLogger )
                                            {
                                                '/filelogger9'
                                                ('/flp9:LogFile={0};Verbosity=d' -f $logFilePath)
                                            }
                                      } | Where-Object { $_ }
        $separator = '{0}VERBOSE:               ' -f [Environment]::NewLine
        Write-Verbose -Message ('  Target      {0}' -f ($target -join $separator))
        Write-Verbose -Message ('  Property    {0}' -f ($property -join $separator))
        Write-Verbose -Message ('  Argument    {0}' -f ($msbuildArgs -join $separator))

        $propertyArgs = $property | ForEach-Object { 
            $item = $_
            $name,$value = $item -split '=',2
            $value = $value.Trim('"')
            $value = $value.Trim("'")
            if( $value.EndsWith( '\' ) )
            {
                $value = '{0}\' -f $value
            }
            '/p:{0}="{1}"' -f $name,($value -replace ' ','%20')
        }

        $targetArg = '/t:{0}' -f ($target -join ';')

        & $msbuildExePath $projectPath $targetArg $propertyArgs $msbuildArgs /nologo
        if( $LASTEXITCODE -ne 0 )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('MSBuild exited with code {0}.' -f $LASTEXITCODE)
        }
    }
}
