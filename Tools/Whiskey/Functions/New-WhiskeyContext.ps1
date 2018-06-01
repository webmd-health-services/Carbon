
function New-WhiskeyContext
{
    <#
    .SYNOPSIS
    Creates a context object to use when running builds.

    .DESCRIPTION
    The `New-WhiskeyContext` function creates a `Whiskey.Context` object used when running builds. It:

    * Reads in the whiskey.yml file containing the build you want to run.
    * Creates a ".output" directory in the same directory as your whiskey.yml file for storing build output, logs, results, temp files, etc.
    * Reads build metadata created by the current build server (if being run by a build server).
    * Sets the version number to "0.0.0".

    ## Whiskey.Context

    The `Whiskey.Context` object has the following properties. ***Do not use any property not defined below.*** Also, these properties are ***read-only***. If you write to them, Bad Things (tm) could happen.

    * `BuildMetadata`: a `Whiskey.BuildInfo` object representing build metadata provided by the build server.
    * `BuildRoot`: a `System.IO.DirectoryInfo` object representing the directory the YAML configuration file is in.
    * `ByBuildServer`: a flag indicating if the build is being run by a build server.
    * `ByDeveloper`: a flag indicating if the build is being run by a developer.
    * `Environment`: the environment the build is running in.
    * `OutputDirectory`: a `System.IO.DirectoryInfo` object representing the path to a directory where build output, reports, etc. should be saved. This directory is created for you.
    * `ShouldClean`: a flag indicating if the current build is running in clean mode.
    * `ShouldInitialize`: a flag indicating if the current build is running in initialize mode.
    * `Temp`: the temporary work directory for the current task.
    * `Version`: a `Whiskey.BuildVersion` object representing version being built (see below).

    Any other property is considered private and may be removed, renamed, and/or reimplemented at our discretion without notice.

    ## Whiskey.BuildInfo

    The `Whiskey.BuildInfo` object has the following properties.  ***Do not use any property not defined below.*** Also, these properties are ***read-only***. If you write to them, Bad Things (tm) could happen.

    * `BuildNumber`: the current build number. This comes from the build server. (If the build is being run by a developer, this is always "0".) It increments with every new build (or should). This number is unique only to the current build job.
    * `ScmBranch`: the branch name from which the current build is running.
    * `ScmCommitID`: the unique commit ID from which the current build is running. The commit ID distinguishes the current commit from all others in the source repository and is the same across copies of a repository.

    ## Whiskey.BuildVersion

    The `Whiskey.BuildVersion` object has the following properties.  ***Do not use any property not defined below.*** Also, these properties are ***read-only***. If you write to them, Bad Things (tm) could happen.

    * `SemVer2`: the version currently being built.
    * `Version`: a `System.Version` object for the current build. Only major, minor, and patch/build numbers will be filled in.
    * `SemVer1`: a semver version 1 compatible version of the current build.
    * `SemVer2NoBuildMetadata`: the current version without any build metadata.

    .EXAMPLE
    New-WhiskeyContext -Path '.\whiskey.yml'

    Demonstrates how to create a context for a developer build.
    #>
    [CmdletBinding()]
    [OutputType([Whiskey.Context])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The environment you're building in.
        $Environment,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the `whiskey.yml` file that defines build settings and tasks.
        $ConfigurationPath,

        [string]
        # The place where downloaded tools should be cached. The default is the build root.
        $DownloadRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $ConfigurationPath = Resolve-Path -LiteralPath $ConfigurationPath -ErrorAction Ignore
    if( -not $ConfigurationPath )
    {
        throw ('Configuration file path ''{0}'' does not exist.' -f $PSBoundParameters['ConfigurationPath'])
    }

    $config = Import-WhiskeyYaml -Path $ConfigurationPath

    if( $config.ContainsKey('Build') -and $config.ContainsKey('BuildTasks') )
    {
        throw ('{0}: The configuration file contains both "Build" and the deprecated "BuildTasks" pipelines. Move all your build tasks under "Build" and remove the "BuildTasks" pipeline.' -f $ConfigurationPath)
    }

    $buildPipelineName = 'Build'
    if( $config.ContainsKey('BuildTasks') )
    {
        $buildPipelineName = 'BuildTasks'
        Write-Warning ('{0}: The default "BuildTasks" pipeline has been renamed to "Build". Backwards compatibility with "BuildTasks" will be removed in the next major version of Whiskey. Rename your "BuildTasks" pipeline to "Build".' -f $ConfigurationPath)
    }

    if( $config.ContainsKey('Publish') -and $config.ContainsKey('PublishTasks') )
    {
        throw ('{0}: The configuration file contains both "Publish" and the deprecated "PublishTasks" pipelines. Move all your publish tasks under "Publish" and remove the "PublishTasks" pipeline.' -f $ConfigurationPath)
    }

    if( $config.ContainsKey('PublishTasks') )
    {
        Write-Warning ('{0}: The default "PublishTasks" pipeline has been renamed to "Publish". Backwards compatibility with "PublishTasks" will be removed in the next major version of Whiskey. Rename your "PublishTasks" pipeline to "Publish".' -f $ConfigurationPath)
    }

    $buildRoot = $ConfigurationPath | Split-Path
    if( -not $DownloadRoot )
    {
        $DownloadRoot = $buildRoot
    }

    [Whiskey.BuildInfo]$buildMetadata = Get-WhiskeyBuildMetadata
    $publish = $false
    $byBuildServer = $buildMetadata.IsBuildServer
    $prereleaseInfo = ''
    if( $byBuildServer )
    {
        $branch = $buildMetadata.ScmBranch

        if( $config.ContainsKey( 'PublishOn' ) )
        {
            Write-Verbose -Message ('PublishOn')
            foreach( $publishWildcard in $config['PublishOn'] )
            {
                $publish = $branch -like $publishWildcard
                if( $publish )
                {
                    Write-Verbose -Message ('           {0}    -like  {1}' -f $branch,$publishWildcard)
                    break
                }
                else
                {
                    Write-Verbose -Message ('           {0} -notlike  {1}' -f $branch,$publishWildcard)
                }
            }
        }
    }

    $versionTaskExists = $config[$buildPipelineName] |
                            Where-Object { $_ -and ($_ | Get-Member -Name 'Keys') } |
                            Where-Object { $_.Keys | Where-Object { $_ -eq 'Version' } }
    if( -not $versionTaskExists -and ($config.ContainsKey('PrereleaseMap') -or $config.ContainsKey('Version') -or $config.ContainsKey('VersionFrom')) )
    {
        Write-Warning ('{0}: The ''PrereleaseMap'', ''Version'', and ''VersionFrom'' properties are obsolete and will be removed in Whiskey 1.0. They were replaced with the ''Version'' task. Add a ''Version'' task as the first task in your build pipeline. If your current whiskey.yml file looks like this:

    Version: 1.2.3

    PrereleaseMap:
    - "alpha/*": alpha
    - "release/*": rc

add a Version task to your build pipeline that looks like this:

    Build:
    - Version:
        Version: 1.2.3
        Prerelease:
        - "alpha/*": alpha.$(WHISKEY_BUILD_NUMBER)
        - "release/*": rc.$(WHISKEY_BUILD_NUMBER)

You must add the ".$(WHISKEY_BUILD_NUMBER)" string to each prerelease version. Whiskey no longer automatically adds a prerelease version number for you.

If you use the "VersionFrom" property, your whiskey.yml file looks something like this:

    VersionFrom: Whiskey\Whiskey.psd1

Update it to look like this:

    Build:
    - Version:
        Path: Whiskey\Whiskey.psd1

Whiskey also no longer automatically adds build metadata to your version number. To preserve Whiskey''s old default build metadata, add a "Build" property to your new "Version" task that looks like this:

    Build:
    - Version:
        Version: 1.2.3
        Build: $(WHISKEY_SCM_BRANCH).$(WHISKEY_SCM_COMMIT_ID.Substring(0,7))

    ' -f $ConfigurationPath)

        $versionTask = $null

        $versionTask = @{
                            Version = ('{0:yyyy.Mdd}.$(WHISKEY_BUILD_NUMBER)' -f (Get-Date))
                            Build = '$(WHISKEY_SCM_BRANCH).$(WHISKEY_SCM_COMMIT_ID)'
                        }

        if( $config['Version'] )
        {
            $versionTask['Version'] = $config['Version']
        }
        elseif( $config['VersionFrom'] )
        {
            $versionTask.Remove('Version')
            $versionTask['Path'] = $config['VersionFrom']
        }

        if( $config['PrereleaseMap'] )
        {
            $versionTask['Prerelease'] = $config['PrereleaseMap'] |
                                            ForEach-Object {
                                                if( -not ($_ | Get-Member 'Keys') )
                                                {
                                                    return $_
                                                }

                                                $newMap = @{ }
                                                foreach( $key in $_.Keys )
                                                {
                                                    $value = $_[$key]
                                                    $newMap[$key] = '{0}.$(WHISKEY_BUILD_NUMBER)' -f $value
                                                }
                                                $newMap
                                            }

        }

        if( $versionTask )
        {
            if( -not $config[$buildPipelineName] )
            {
                $config[$buildPipelineName] = @()
            }

            $config[$buildPipelineName] = & {
                                            @{
                                                Version = $versionTask
                                            }
                                            $config[$buildPipelineName]
                                    }
        }
    }

    $outputDirectory = Join-Path -Path $buildRoot -ChildPath '.output'
    if( -not (Test-Path -Path $outputDirectory -PathType Container) )
    {
        New-Item -Path $outputDirectory -ItemType 'Directory' -Force | Out-Null
    }

    $context = New-WhiskeyContextObject
    $context.BuildRoot = $buildRoot
    $runBy = [Whiskey.RunBy]::Developer
    if( $byBuildServer )
    {
        $runBy = [Whiskey.RunBy]::BuildServer
    }
    $context.RunBy = $runBy
    $context.BuildMetadata = $buildMetadata
    $context.Configuration = $config
    $context.ConfigurationPath = $ConfigurationPath
    $context.DownloadRoot = $DownloadRoot
    $context.Environment = $Environment
    $context.OutputDirectory = $outputDirectory
    $context.Publish = $publish
    $context.RunMode = [Whiskey.RunMode]::Build

    if( $config['Variable'] )
    {
        Write-Error -Message ('{0}: The ''Variable'' property is no longer supported. Use the `SetVariable` task instead. Move your `Variable` property (and values) into your `Build` pipeline as the first task. Rename `Variable` to `SetVariable`.' -f $ConfigurationPath) -ErrorAction Stop
    }

    if( $versionTaskExists )
    {
        $context.Version = New-WhiskeyVersionObject -SemVer '0.0.0'
    }
    else
    {
        Write-Warning ('Whiskey''s default, date-base default version number is OBSOLETE. Beginning with Whiskey 1.0, the default Whiskey version number will be 0.0.0. Use the Version task to set your own custom version. For example, this Version task preserves the existing behavior:

    Build
    - Version:
        Version: $(WHISKEY_BUILD_STARTED_AT.ToString(''yyyy.Mdd'')).$(WHISKEY_BUILD_NUMBER)
        Build: $(WHISKEY_SCM_BRANCH).$(WHISKEY_SCM_COMMIT_ID)
 ')
        $rawVersion = '{0:yyyy.Mdd}.{1}' -f (Get-Date),$context.BuildMetadata.BuildNumber
        if( $context.ByBuildServer )
        {
            $branch = $buildMetadata.ScmBranch
            $branch = $branch -replace '[^A-Za-z0-9-]','-'
            $commitID = $buildMetadata.ScmCommitID.Substring(0,7)
            $buildInfo = '{0}.{1}.{2}' -f $buildMetadata.BuildNumber,$branch,$commitID
            $rawVersion = '{0}+{1}' -f $rawVersion,$buildInfo
        }
        $context.Version = New-WhiskeyVersionObject -SemVer $rawVersion
    }

    return $context
}

