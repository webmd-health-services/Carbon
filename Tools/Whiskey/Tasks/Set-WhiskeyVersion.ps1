
 function Set-WhiskeyVersion 
{
    <#
    .SYNOPSIS
    Sets the version for the current build.

    .DESCRIPTION
    The `Version` task sets the version for the current build. Whiskey only supports [semantic versions](http://semver.org).
    
    You can set the version explicitly with the `Version` property. Whiskey can read the version from a .NET Core .csproj file, a PowerShell module manifest, or a Node package.json file. Set the `Path` property to the path to the file to read from. If it is unsupported or doesn't contain a version, the build will fail.

    You can set custom prerelease metadata with the `Prerelease` property and custom build metadata with the `Build` property. These properties ovewrite any existing prereleaes version of build metadata from the `Version` property or the version read from a file. Prerelease metadata must only consist of letters, numbers, periods, or hyphens. Build metadata has the same restriction, but Whiskey replaces all non letters, numbers, and periods with hyphens (since build metadata typically comes from systems that don't have these restrictions).

    When run by a developer, the version will never have any build metadata (i.e. build metadata is only available when running under/by a build server).

    ## Per-Branch Prerelease Metadata

    The `Prerelease` property also allows you to have different prerelease metadata on different branches. Set the `Prerelease` property to a list of key/value pairs. The key should be a wildcard pattern that matches branch names. The value should be the prerelease metadata to use on any branch that matches that wildcard. The `Version` task uses the first item that matches the current branch.

    So, if you wanted to publish alpha versions in branches that begin with "feature/" and beta versions on a branch named "develop", your "Prerelease" property would look like this:

        Build:
        - Version:
            Version: 5.6.3
            Prerelease:
            - feature/*: alpha.$(WHISKEY_BUILD_NUMBER)
            - develop: beta.$(WHISKEY_BUILD_NUMBER)

    ## Reading Versions from Files

    Some frameworks and platforms already have well-known locations they expect you to put your version number. Whiskey can read your version from some of these files.

    ### PowerShell Module Manifest

    Your module manifest must be formatted correctly and contain the `ModuleVersion` property, e.g.

        @{
            # ...snip...
            ModuleVersion = '0.31.0'
            # ...snip...
        }

    ### Node package.json

    Whiskey looks for a "version" property on the root object, e.g.

        {
            "name": "some node module name",
            "version": "0.31.0"
            "description": "some description",
            "// ...snip..."
        }

    ### .NET Core .csproj

    Whiskey looks for a "Version" element under a "PropertyGroup" element under the project's root "Project" element, e.g.

        <Project Sdk="Microsoft.NET.Sdk">
            <PropertyGroup>
                <!-- ...snip... -->
                <Version>0.31.0</Version>
                <!-- ...snip... -->
            </PropertyGroup>
            <!-- ...snip... -->
        </Project>

    # Properties

    * **Version**: The version for the current build.
    * **Path**: The path to a file from which Whiskey will read the current version. Whiskey supports .NET Core .csproj files, PowerShell module manifests, or Node package.json files.
    * **Prerelease**: Any custom pre-release metadata to add to the version. This will overwrite any existing prerelease metadata. You usually only use this property when reading a version from a file with the `Path` property since some platforms don't natively support prerelease metadata. 
    * **Build**: Any custom build metadata to add to the version. This will overwrite any existing build metadata. You usually only use this property when reading a version from a file with the `Path` property since some platforms don't natively support prerelease metadata.

    # Examples

    ## Example 1

        Build:
        - Version: 5.6.3

    Demonstrates the simplest syntax to set the version for the current build. Do this if you want to completely control the version for every build.

    ## Example 2

        Build:
        - Version: 
            Version: 5.6.3
            OnlyBy: BuildServer

    Demonstrates the standard syntax to set the version for the current build. Do this if you want to use other properties.
    
    ## Example 3
    
        Build:
        - Version: $(WHISKEY_BUILD_STARTED_AT.ToString('yyyy.M.d'))+$(WHISKEY_BUILD_NUMBER).$(WHISKEY_SCM_BRANCH).$(WHISKEY_SCM_COMMIT_ID.Substring(0,7))

    Demonstrates how to use a dynamic, date-based version number. In this example, if the current date is 6 Feb. 2018, the current build number is `43`, your current branch is `develop`, and your current commit ID is `c7d950be9982156d5d9aaa1a6c23594eaaba9b27`, your version number would be '2018.2.16+43.develop.c7d950b'.

    This is a useful strategy for versioning applications that don't expose an API so don't technically need to be semantically versioned.

    ### Example 4

        Build:
        - Version:
            Path: Whiskey\Whiskey.psd1
            Prerelease: alpha.$(WHISKEY_BUILD_NUMBER)
            Build: $(WHISKEY_SCM_BRANCH).$(WHISKEY_SCM_COMMIT_ID.Substring(0,7))

    Demonstrates how to read the version from a file, in this case a PowerShell module manifest. Since PowerShell doesn't support semantic versions, it uses the `Prerelease` and `Build` properties to add that metadata to the version. This metadata may or may not be used by other tasks in your build. 

    ### Example 5

        Build:
        - Version:
            Path: Assembly\Whiskey.csproj
            Prerelease: 
            - feature/*: alpha.$(WHISKEY_BUILD_NUMBER)
            - bugfix/*: beta.$(WHISKEY_BUILD_NUMBER)
            - develop: beta.$(WHISKEY_BUILD_NUMBER)
            - release: rc.$(WHISKEY_BUILD_NUMBER)
            - hotfix/*: rc.$(WHISKEY_BUILD_NUMBER)

    Demonstrates how to have custom prerelease metadata on different branches. Set the "Prerelease" element to a list of key/value pairs. The keys are wildcard patterns that match branch names in your source code repository. The value is the prerelease metadata to use.

    In this example, if the current build number is 43, all builds on branches that match the wildcard pattern "feature/*" would have prerelease be "alpha.43", branches that matched pattern "bugfix/*" would have prerelease "beta.43", etc.

    ### Example 6
        
        Build:
        - Version:
            Version: 4.5.6
        - Version:
            OnlyBy: BuildServer
            Prerelease: alpha.$(WHISKEY_BUILD_NUMBER)
            Build: $(WHISKEY_SCM_BRANCH).$(WHISKEY_SCM_COMMIT_ID.Substring(0,7))

    Demonstrates that you can use the Version task to set just the Prerelease version and the Build metadata without affecting the version number. In this example, when being bun by a developer, the version number will be 4.5.6; when being run by the build server, the version number will be "4.5.6-alpha.6+develop.775e171" (assuming the current branch is "develop" and the current commit is "775e1711a1fe190f59f4c46ae3063f12e0040e58").
    #>
    [CmdletBinding()]
    [Whiskey.Task("Version")]
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

    function ConvertTo-SemVer
    {
        param(
            [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
            $InputObject,
            $PropertyName,
            $VersionSource
        )

        process
        {
            [SemVersion.SemanticVersion]$semver = $null
            if( -not [SemVersion.SemanticVersion]::TryParse($rawVersion,[ref]$semver) )
            {
                if( $VersionSource )
                {
                    $VersionSource = ' ({0})' -f $VersionSource
                }
                $optionalParam = @{ }
                if( $PropertyName )
                {
                    $optionalParam['PropertyName'] = $PropertyName
                }
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('''{0}''{1} is not a semantic version. See http://semver.org for documentation on semantic versions.' -f $rawVersion,$VersionSource) @optionalParam
            }
            return $semver
        }
    }

    [Whiskey.BuildVersion]$buildVersion = $TaskContext.Version
    [SemVersion.SemanticVersion]$semver = $buildVersion.SemVer2

    if( $TaskParameter[''] )
    {
        $rawVersion = $TaskParameter['']
        $semVer = $rawVersion | ConvertTo-SemVer -PropertyName 'Version'
    }
    elseif( $TaskParameter['Version'] )
    {
        $rawVersion = $TaskParameter['Version']
        $semVer = $rawVersion | ConvertTo-SemVer -PropertyName 'Version'
    }
    elseif( $TaskParameter['Path'] )
    {
        $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'
        if( -not $path )
        {
            return
        }

        $fileInfo = Get-Item -Path $path
        if( $fileInfo.Extension -eq '.psd1' )
        {
            $rawVersion = Test-ModuleManifest -Path $Path -ErrorAction Ignore  | Select-Object -ExpandProperty 'Version'
            if( -not $rawVersion )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Unable to read version from PowerShell module manifest ''{0}'': the manifest is invalid or doesn''t contain a ''ModuleVersion'' property.' -f $path)
            }
            Write-WhiskeyVerbose -Context $TaskContext -Message ('Read version ''{0}'' from PowerShell module manifest ''{1}''.' -f $rawVersion,$path)
            $semver = $rawVersion | ConvertTo-SemVer -VersionSource ('from PowerShell module manifest ''{0}''' -f $path)
        }
        elseif( $fileInfo.Name -eq 'package.json' )
        {
            try
            {
                $rawVersion = Get-Content -Path $path -Raw | ConvertFrom-Json | Select-Object -ExpandProperty 'Version' -ErrorAction Ignore
            }
            catch
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Node package.json file ''{0}'' contains invalid JSON.' -f $path)
            }
            if( -not $rawVersion )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Unable to read version from Node package.json ''{0}'': the ''Version'' property is missing.' -f $path)
            }
            Write-WhiskeyVerbose -Context $TaskContext -Message ('Read version ''{0}'' from Node package.json ''{1}''.' -f $rawVersion,$path)
            $semVer = $rawVersion | ConvertTo-SemVer -VersionSource ('from Node package.json file ''{0}''' -f $path)
        }
        elseif( $fileInfo.Extension -eq '.csproj' )
        {
            [xml]$csprojXml = $null
            try
            {
                $csprojxml = Get-Content -Path $Path -Raw
            }
            catch
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('.NET .cspoj file ''{0}'' contains invalid XMl.' -f $path)
            }

            if( $csprojXml.DocumentElement.Attributes['xmlns'] )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('.NET .csproj file ''{0}'' has an "xmlns" attribute. .NET Core/Standard .csproj files should not have a default namespace anymore (see https://docs.microsoft.com/en-us/dotnet/core/migration/). Please remove the "xmlns" attribute from the root "Project" document element. If this is a .NET framework .csproj, it doesn''t support versioning. Use the Whiskey Version task''s Version property to version your assemblies.' -f $path)
            }
            $csprojVersionNode = $csprojXml.SelectSingleNode('/Project/PropertyGroup/Version')
            if( -not $csprojVersionNode )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''/Project/PropertyGroup/Version'' does not exist in .NET .csproj file ''{0}''. Please create this element and set it to the MAJOR.MINOR.PATCH version of the next version of your assembly.' -f $path)
            }
            $rawVersion = $csprojVersionNode.InnerText
            Write-WhiskeyVerbose -Context $TaskContext -Message ('Read version ''{0}'' from .NET Core .csproj ''{1}''.' -f $rawVersion,$path)
            $semver = $rawVersion | ConvertTo-SemVer -VersionSource ('from .NET .csproj file ''{0}''' -f $path)
        }
    }

    $prerelease = $TaskParameter['Prerelease']
    if( $prerelease -isnot [string] )
    {
        $foundLabel = $false
        foreach( $object in $prerelease )
        {
            foreach( $map in $object )
            {
                if( -not ($map | Get-Member -Name 'Keys') )
                {
                    Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Prerelease' -Message ('Unable to find keys in ''[{1}]{0}''. It looks like you''re trying use the Prerelease property to map branches to prerelease versions. If you want a static prerelease version, the syntax should be:
    
    Build:
    - Version:
        Prerelease: {0}
        
If you want certain branches to always have certain prerelease versions, set Prerelease to a list of key/value pairs:
    
    Build:
    - Version:
        Prerelease:
        - feature/*: alpha.$(WHISKEY_BUILD_NUMBER)
        - develop: beta.$(WHISKEY_BUILD_NUMBER)
    ' -f $map,$map.GetType().FullName)
                }
                foreach( $wildcardPattern in $map.Keys )
                {
                    if( $TaskContext.BuildMetadata.ScmBranch -like $wildcardPattern )
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}     -like  {1}' -f $TaskContext.BuildMetadata.ScmBranch,$wildcardPattern)
                        $foundLabel = $true
                        $prerelease = $map[$wildcardPattern]
                        break
                    }
                    else
                    {
                        Write-WhiskeyVerbose -Context $TaskContext -Message ('{0}  -notlike  {1}' -f $TaskContext.BuildMetadata.ScmBranch,$wildcardPattern)
                    }
                }
            }
        }

        if( -not $foundLabel )
        {
            $prerelease = ''
        }
    }

    if( $prerelease )
    {
        $buildSuffix = ''
        if( $semver.Build )
        {
            $buildSuffix = '+{0}' -f $semver.Build
        }

        $rawVersion = '{0}.{1}.{2}-{3}{4}' -f $semver.Major,$semver.Minor,$semver.Patch,$prerelease,$buildSuffix
        if( -not [SemVersion.SemanticVersion]::TryParse($rawVersion,[ref]$semver) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Prerelease' -Message ('''{0}'' is not a valid prerelease version. Only letters, numbers, hyphens, and periods are allowed. See http://semver.org for full documentation.' -f $prerelease)
        }
    }

    $build = $TaskParameter['Build']
    if( $build )
    {
        $prereleaseSuffix = ''
        if( $semver.Prerelease )
        {
            $prereleaseSuffix = '-{0}' -f $semver.Prerelease
        }
        
        $build = $build -replace '[^A-Za-z0-9\.-]','-'
        $rawVersion = '{0}.{1}.{2}{3}+{4}' -f $semver.Major,$semver.Minor,$semver.Patch,$prereleaseSuffix,$build
        if( -not [SemVersion.SemanticVersion]::TryParse($rawVersion,[ref]$semver) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -PropertyName 'Build' -Message ('''{0}'' is not valid build metadata. Only letters, numbers, hyphens, and periods are allowed. See http://semver.org for full documentation.' -f $build)
        }
    }

    # Build metadata is only available when running under a build server.
    if( $TaskContext.ByDeveloper )
    {
        $semver = New-Object -TypeName 'SemVersion.SemanticVersion' $semver.Major,$semVer.Minor,$semVer.Patch,$semver.Prerelease
    }

    $buildVersion.SemVer2 = $semver
    Write-WhiskeyInfo -Context $TaskContext -Message ('Building version {0}' -f $semver)
    $buildVersion.Version = [version]('{0}.{1}.{2}' -f $semver.Major,$semver.Minor,$semver.Patch)
    Write-WhiskeyVerbose -Context $TaskContext -Message ('Version                 {0}' -f $buildVersion.Version)
    $buildVersion.SemVer2NoBuildMetadata = New-Object 'SemVersion.SemanticVersion' ($semver.Major,$semver.Minor,$semver.Patch,$semver.Prerelease)
    Write-WhiskeyVerbose -Context $TaskContext -Message ('SemVer2NoBuildMetadata  {0}' -f $buildVersion.SemVer2NoBuildMetadata)
    $semver1Prerelease = $semver.Prerelease
    if( $semver1Prerelease )
    {
        $semver1Prerelease = $semver1Prerelease -replace '[^A-Za-z0-9]',''
    }
    $buildVersion.SemVer1 = New-Object 'SemVersion.SemanticVersion' ($semver.Major,$semver.Minor,$semver.Patch,$semver1Prerelease)
    Write-WhiskeyVerbose -Context $TaskContext -Message ('SemVer1                 {0}' -f $buildVersion.SemVer1)
}
