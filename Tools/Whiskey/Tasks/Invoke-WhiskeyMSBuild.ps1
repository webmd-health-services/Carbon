function Invoke-WhiskeyMSBuild
{
    <#
    .SYNOPSIS
    The MSBuild task runs msbuild.exe, the Microsoft Build tool.

    .DESCRIPTION
    The MSBuild task runs the "build" target against one or more files, specified with the `Path` property. (In clean mode, it runs the "clean" target instead.) These files must be in formats that MSBuild recognizes (e.g. *.sln, *.csproj, etc.). You can change what build targets to run using the `Target` property.

    When run by a developers, this task builds using Debug configuration. When run by a build server, it builds using Release configuration.

    For each solution file in the `Path` property (i.e. a file whose extension is .sln), the MSBuild task will restore that solutions's NuGet packages before the build begins, i.e. it runs `nuget.exe restore PATH_TO.sln`.

    When run on the build server, the MSBuild task adds the current version being built to all AsssemblyInfo.cs files in or under the same directory as the file being built.

    Specifically, these assembly attributes are addded:

        [assembly: System.Reflection.AssemblyVersion("VERSION_NUMBER")]
        [assembly: System.Reflection.AssemblyFileVersion("VERSION_NUMBER")]
        [assembly: System.Reflection.AssemblyInformationalVersion("VERSION_NUMBER+BUILD_METADATA")]

    If an AssemblyInfo.cs file already has one of these attributes, the existing attribute is replaced. Build metadata is added to the end of the version in the AssemblyInformationalVersion attribute's value.

    The build fails if msbuild.exe returns a non-zero exist code.

    The MSBuild task looks up installed versions of MSBuild in the "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\MSBuild\ToolsVersions' registry key. For each key it finds, it uses the "MSBuildToolsPath" property to locate that version's MSBuild.exe executable.
    
    Versions of MSBuild that ship with Visual Studio 2017 and later don't appear in the registry, so the MSBuild task also uses the `Get-VSSetupInstance` function in the VSSetup PowerShell module to find installed instances of Visual Studio 2017 (and later). The task looks for versions of MSBuild in the "MSBuild" directory under each Visual Studio instance's installation path. Under each version, it looks for 64-bit MSBuild.exe at "Bin\amd64\MSBuild.exe" and 32-bit MSBuild.exe at "Bin\MSBuild.exe".

    ## Property

    * **Path** (*mandatory*): A list of one or more paths to files that MSBuild can build. Files are built in the order they appear in this list. Wildcards are permitted.
    * **Verbosity**: Controls the verbosity level of MSBuild's output. The default is minimal. On build servers, the default is debug. Should be one of quiet, minimal, normal, debug, or diagnostic.
    * **Property**: A list of additional MSBuild properties to pass to MSBuild, e.g. Disable_CopyWebApplication=True. Must be of the form NAME=VALUE.
    * **OutputDirectory**: The directory where assemblies should be compiled to. The default is the location specified in each .csproj file.
    * **CpuCount**: The number of MSBuild processes to use when building. The default is the number of cores/CPUs on the current computer. Setting this to 1 disables parallel builds.
    * **NoMaxCpuCountArgument**: This disables multi-CPU builds by not passing the /maxcpucount argument to MSBuild. Useful if you're building with versions of MSBuild that don't support /maxcpucount.
    * **NoFileLogger**: Disables logging debug output to a log file in the output directory.
    * **Argument**: A list of arguments to pass to msbuild.exe.
    * **Target**: A list of build targets to run. The default is build.
    * **Version**: The version of MSBuild to use. By default, uses the most recent/latest version of MSBuild installed. You usually will want to pin this to a specific version. Valid values are 15.0 (Visual Studio 2017), 14.0 (Visual Studio 2015) 12.0 (Visual Studio 2013), 4.0, 3.5, or 2.0.
    * **NuGetVersion**: The version of NuGet to use to restore packages. The default is to use the latest version.
    * **Use32Bit**: Set to `true` to use a 32-bit version of MSBuild.exe. The default is to use a version that matches the processor architecture of the current computer.

    ## Examples

        Build:
        - MSBuild:
            Path: MySolution.sln

    Demonstrates how to use the MSBuild task to build a Visual Studio solution file.
    #>
    [Whiskey.Task("MSBuild",SupportsClean=$true)]
    [CmdletBinding()]
    param(
        [Whiskey.Context]
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
        
        Build:
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
    if( $TaskParameter.ContainsKey('Use32Bit') -and ($TaskParameter['Use32Bit'] | ConvertFrom-WhiskeyYamlScalar) )
    {
        $msbuildExePath = $msbuildInfo.Path32
        if( -not $msbuildExePath )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('A 32-bit version of MSBuild {0} does not exist.' -f $version)
        }
    }
    Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}' -f $msbuildExePath)
    
    $target = @( 'build' )
    if( $TaskContext.ShouldClean )
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
        Write-WhiskeyVerbose -Context $TaskContext -Message ('  {0}' -f $projectPath)
        $errors = $null
        if( $projectPath -like '*.sln' )
        {
            if( $TaskContext.ShouldClean )
            {
                $packageDirectoryPath = Join-Path -path ( Split-Path -Path $projectPath -Parent ) -ChildPath 'packages'
                if( Test-Path -Path $packageDirectoryPath -PathType Container )
                {
                    Write-WhiskeyVerbose -Context $TaskContext -Message ('  Removing NuGet packages at {0}.' -f $packageDirectoryPath)
                    Remove-Item $packageDirectoryPath -Recurse -Force
                }
            }
            else
            {
                Write-WhiskeyVerbose -Context $TaskContext -Message ('  Restoring NuGet packages.')
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
                    Write-WhiskeyVerbose -Context $TaskContext -Message ('    Updating version in {0}.' -f $assemblyInfoPath)
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
        Write-WhiskeyVerbose -Context $TaskContext -Message ('  Target      {0}' -f ($target -join $separator))
        Write-WhiskeyVerbose -Context $TaskContext -Message ('  Property    {0}' -f ($property -join $separator))
        Write-WhiskeyVerbose -Context $TaskContext -Message ('  Argument    {0}' -f ($msbuildArgs -join $separator))

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
