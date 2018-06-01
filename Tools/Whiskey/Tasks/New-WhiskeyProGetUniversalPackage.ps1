
function New-WhiskeyProGetUniversalPackage
{
    [CmdletBinding()]
    [Whiskey.Task("ProGetUniversalPackage")]
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

    $manifestProperties = @{}
    if( $TaskParameter.ContainsKey('ManifestProperties') )
    {
        $manifestProperties = $TaskParameter['ManifestProperties']
        foreach( $taskProperty in @( 'Name', 'Description', 'Version' ))
        {
            if( $manifestProperties.ContainsKey($taskProperty) )
            {
                Stop-WhiskeyTask -TaskContext $TaskContext -Message ('"ManifestProperties" contains key "{0}". This property cannot be manually defined in "ManifestProperties" as it is set automatically from the corresponding task property "{0}".' -f $taskProperty)
            }
        }
    }

    foreach( $mandatoryProperty in @( 'Name', 'Description' ) )
    {
        if( -not $TaskParameter.ContainsKey($mandatoryProperty) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''{0}'' is mandatory.' -f $mandatoryProperty)
        }
    }

    $name = $TaskParameter['Name']
    $validNameRegex = '^[0-9A-z\-\._]{1,50}$'
    if ($name -notmatch $validNameRegex)
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message '"Name" property is invalid. It should be a string of one to fifty characters: numbers (0-9), upper and lower-case letters (A-z), dashes (-), periods (.), and underscores (_).'
    }

    $version = $TaskParameter['Version']

    # ProGet uses build metadata to distinguish different versions, so we can't use a full semantic version.
    if( $version )
    {
        if( ($version -notmatch '^\d+\.\d+\.\d+$') )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Version'' is invalid. It must be a three part version number, i.e. MAJOR.MINOR.PATCH.')
        }
        [SemVersion.SemanticVersion]$semVer = $null
        if( -not ([SemVersion.SemanticVersion]::TryParse($version, [ref]$semVer)) )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Version'' is not a valid semantic version.')
        }
        $semVer = New-Object 'SemVersion.SemanticVersion' $semVer.Major,$semVer.Minor,$semVer.Patch,$TaskContext.Version.SemVer2.Prerelease,$TaskContext.Version.SemVer2.Build
        $version = New-WhiskeyVersionObject -SemVer $semVer
    }
    else
    {
        $version = $TaskContext.Version
    }

    $compressionLevel = 1
    if( $TaskParameter['CompressionLevel'] )
    {
        $compressionLevel = $TaskParameter['CompressionLevel'] | ConvertFrom-WhiskeyYamlScalar -ErrorAction Ignore
        if( $compressionLevel -eq $null )
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''CompressionLevel'': ''{0}'' is not a valid compression level. It must be an integer between 0-9.' -f $TaskParameter['CompressionLevel']);
        }
    }

    $parentPathParam = @{ }
    $sourceRoot = $TaskContext.BuildRoot
    if( $TaskParameter.ContainsKey('SourceRoot') )
    {
        $sourceRoot = $TaskParameter['SourceRoot'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'SourceRoot'
        $parentPathParam['ParentPath'] = $sourceRoot
    }

    if( -not $manifestProperties.ContainsKey('Name') )
    {
        $manifestProperties['Name'] = $name
    }

    if( -not $manifestProperties.ContainsKey('Title') )
    {
        $manifestProperties['Title'] = $name
    }

    if( -not $manifestProperties.ContainsKey('Description') )
    {
        $manifestProperties['Description'] = $TaskParameter['Description']
    }

    if( -not $manifestProperties.ContainsKey('Version') )
    {
        $manifestProperties['Version'] = $version.SemVer2NoBuildMetadata.ToString()
    }

    $tempRoot = $TaskContext.Temp
    $tempPackageRoot = Join-Path -Path $tempRoot -ChildPath 'package'
    New-Item -Path $tempPackageRoot -ItemType 'Directory' | Out-Null

    $upackJsonPath = Join-Path -Path $tempRoot -ChildPath 'upack.json'
    $manifestProperties | ConvertTo-Json | Set-Content -Path $upackJsonPath

    # Add the version.json file
    @{
        Version = $version.Version.ToString();
        SemVer2 = $version.SemVer2.ToString();
        SemVer2NoBuildMetadata = $version.SemVer2NoBuildMetadata.ToString();
        PrereleaseMetadata = $version.SemVer2.Prerelease;
        BuildMetadata = $version.SemVer2.Build;
        SemVer1 = $version.SemVer1.ToString();
    } | ConvertTo-Json -Depth 1 | Set-Content -Path (Join-Path -Path $tempPackageRoot -ChildPath 'version.json')

    function Copy-ToPackage
    {
        param(
            [Parameter(Mandatory=$true)]
            [object[]]
            $Path,

            [Switch]
            $AsThirdPartyItem
        )

        foreach( $item in $Path )
        {
            $override = $False
            if( (Get-Member -InputObject $item -Name 'Keys') )
            {
                $sourcePath = $null
                $override = $True
                foreach( $key in $item.Keys )
                {
                    $destinationItemName = $item[$key]
                    $sourcePath = $key
                }
            }
            else
            {
                $sourcePath = $item
            }
            $pathparam = 'path'
            if( $AsThirdPartyItem )
            {
                $pathparam = 'ThirdPartyPath'
            }

            $sourcePaths = $sourcePath | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName $pathparam @parentPathParam
            if( -not $sourcePaths )
            {
                return
            }

            foreach( $sourcePath in $sourcePaths )
            {
                $relativePath = $sourcePath -replace ('^{0}' -f ([regex]::Escape($sourceRoot))),''
                $relativePath = $relativePath.Trim("\")
                if( -not $override )
                {
                    $destinationItemName = $relativePath
                }

                $destination = Join-Path -Path $tempPackageRoot -ChildPath $destinationItemName
                $parentDestinationPath = ( Split-Path -Path $destination -Parent)

                #if parent doesn't exist in the destination dir, create it
                if( -not ( Test-Path -Path $parentDestinationPath ) )
                {
                    New-Item -Path $parentDestinationPath -ItemType 'Directory' -Force | Out-Null
                }

                if( (Test-Path -Path $sourcePath -PathType Leaf) )
                {
                    Copy-Item -Path $sourcePath -Destination $destination
                }
                else
                {
                    $destinationDisplay = $destination -replace [regex]::Escape($tempRoot),''
                    $destinationDisplay = $destinationDisplay.Trim('\')
                    $taskTempDirectory = $TaskContext.Temp.FullName
                    if( $AsThirdPartyItem )
                    {
                        $robocopyExclude = @( $taskTempDirectory )
                        $whitelist = @( )
                        $operationDescription = 'packaging third-party {0} -> {1}' -f $sourcePath,$destinationDisplay
                    }
                    else
                    {
                        if( -not $TaskParameter['Include'] )
                        {
                            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Include'' is mandatory because ''{0}'' is in your ''Path'' property and it is a directory. The ''Include'' property is a whitelist of files (wildcards supported) to include in your package. Only files in directories that match an item in the ''Include'' list will be added to your package.' -f $sourcePath)
                            return
                        }

                        $robocopyExclude = & {
                            $taskTempDirectory;
                            (Join-Path -Path $destination -ChildPath 'version.json');
                            $TaskParameter['Exclude'];
                        }

                        $operationDescription = 'packaging {0} -> {1}' -f $sourcePath,$destinationDisplay
                        $whitelist = & { 'upack.json' ; $TaskParameter['Include'] }
                    }

                    Write-WhiskeyInfo -Context $TaskContext -Message $operationDescription

                    $robocopyOutputPath = Join-Path -Path $TaskContext.Temp -ChildPath ('RobocopyOutput.{0}.txt' -f [IO.Path]::GetRandomFileName())
                    Invoke-WhiskeyRobocopy -Source $sourcePath.trim("\") -Destination $destination.trim("\") -WhiteList $whitelist -Exclude $robocopyExclude -LogPath $robocopyOutputPath | Out-Null
                    if( $LASTEXITCODE -ge 8 )
                    {
                        $robocopyOutput = Get-Content -Path $robocopyOutputPath -Raw -ErrorAction Ignore
                        if ($robocopyOutput)
                        {
                            $robocopyOutput = $robocopyOutput.Split([Environment]::NewLine) | Where-Object { $_ -ne '' }
                            $robocopyOutput | Write-WhiskeyInfo -Context $TaskContext
                        }

                        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Robocopy failed with exit code {0}' -f $LASTEXITCODE)
                    }

                    # Get rid of empty directories. Robocopy doesn't sometimes.
                    Get-ChildItem -Path $destination -Directory -Recurse |
                        Where-Object { -not ($_ | Get-ChildItem) } |
                        Remove-Item
                }
            }
        }
    }

    if( $TaskParameter['Path'] )
    {
        Copy-ToPackage -Path $TaskParameter['Path']
    }

    if( $TaskParameter.ContainsKey('ThirdPartyPath') -and $TaskParameter['ThirdPartyPath'] )
    {
        Copy-ToPackage -Path $TaskParameter['ThirdPartyPath'] -AsThirdPartyItem
    }

    $badChars = [IO.Path]::GetInvalidFileNameChars() | ForEach-Object { [regex]::Escape($_) }
    $fixRegex = '[{0}]' -f ($badChars -join '')
    $fileName = '{0}.{1}.upack' -f $name,($version.SemVer2NoBuildMetadata -replace $fixRegex,'-')

    $outFile = Join-Path -Path $TaskContext.OutputDirectory -ChildPath $fileName

    Write-WhiskeyVerbose -Context $TaskContext -Message ('Creating universal package {0}' -f $outFile)
    & $7z 'a' '-tzip' ('-mx{0}' -f $compressionLevel) $outFile (Join-Path -Path $tempRoot -ChildPath '*')

    Write-WhiskeyVerbose -Context $TaskContext -Message ('returning package path ''{0}''' -f $outFile)
    $outFile
}
