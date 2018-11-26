
 function Set-WhiskeyVersion
{
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
        elseif( $fileInfo.Name -eq 'metadata.rb' )
        {
            $metadataContent = Get-Content -Path $path -Raw
            $metadataContent = $metadataContent.Split([Environment]::NewLine) | Where-Object { $_ -ne '' }

            $rawVersion = $null
            foreach( $line in $metadataContent )
            {
                if( $line -match '^\s*version\s+[''"](\d+\.\d+\.\d+)[''"]' )
                {
                    $rawVersion = $Matches[1]
                    break
                }
            }

            if( -not $rawVersion )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Unable to locate property "version ''x.x.x''" in metadata.rb file "{0}"' -f $path )
                return
            }

            Write-WhiskeyVerbose -Context $TaskContext -Message ('Read version "{0}" from metadata.rb file "{1}".' -f $rawVersion,$path)
            $semver = $rawVersion | ConvertTo-SemVer -VersionSource ('from metadata.rb file "{0}"' -f $path)
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
