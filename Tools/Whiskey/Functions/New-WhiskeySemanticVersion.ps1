
function New-WhiskeySemanticVersion
{
    <#
    .SYNOPSIS
    Creates a version number that identifies the current build.

    .DESCRIPTION
    The `New-WhiskeySemanticVersion` function gets a semantic version that represents the current build. If called multiple times during a build, you'll get the same verson number back.

    If passed a version, it will return that version with build metadata attached. Any build metadata on the passed-in version is replaced. On a build server, build metadata is the build number, source control branch, and commit ID, e.g. `80.master.deadbee`. When run by developers, the build metadata is the current username and computer name, e.g. `whiskey.desktop001`.

    If not passed a version, or the version passed is null or empty, a date-based version number is generated for you. The major number is the year and the minor number is the month and day, e.g. `2017.808`. If run by a developer, the patch number is set to `0`. If run on a build server, the build number is used.

    Pass any prerelease metadata to the `Prerelease` parameter. If `Version` has a value, then the `Prerelease` parameter is ignored.
    #>
    [CmdletBinding()]
    [OutputType([SemVersion.SemanticVersion])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByVersion')]
        [AllowNull()]
        [object]
        $Version,

        [Parameter(Mandatory=$true,ParameterSetName='ByPath')]
        [object]
        $Path,

        [Parameter(Mandatory=$true)]
        [AllowEmptyString()]
        [string]
        $Prerelease,

        [Parameter(Mandatory=$true)]
        [object]
        $BuildMetadata
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if( $Version )
    {
        $semVersion = $Version | ConvertTo-WhiskeySemanticVersion
    }
    elseif( $Path )
    {
        $Path = Resolve-Path -Path $Path | Select-Object -ExpandProperty ProviderPath
        if( -not $Path )
        {
            Write-Error ('Path to version file ''{0}'' does not exist' -f $path)
        }
        $fileInfo = Get-Item $Path
        if($fileInfo.Name -eq 'package.json')
        {
            $semVersion = Get-Content -Raw -Path $Path | 
                            ConvertFrom-Json -ErrorAction Ignore | 
                            Select-Object -ExpandProperty 'version' -ErrorAction Ignore | 
                            ConvertTo-WhiskeySemanticVersion
            if( -not $semVersion )
            {
                Write-Error -Message ('Unable to get the version to build from the Node.js package.json file ''{0}''. Please make sure the file is valid JSON, that it contains a `version` property, and that the version''s value is a valid semantic version, e.g.
    
    {
        "version": "1.2.3"
    }
    ' -f $fileInfo.FullName)
            }
        }

        if($fileInfo.Extension -eq '.psd1')
        {
            $semVersion = Test-ModuleManifest -Path $Path | 
                            Select-Object -ExpandProperty 'Version' | 
                            ConvertTo-WhiskeySemanticVersion
            if( -not $semVersion )
            {
                Write-Error -Message ('Unable to get the version to build from the PowerShell module manifest file ''{0}''. Please make sure the file is a valid Powershell module manifest and that it contains a `ModuleVersion` property, e.g. 
    
    @{
        ModuleVersion = ''1.2.3'';
    }
    ' -f $fileInfo.FullName)
            }
        }
    }
    else
    {
        $patch = '0'
        if( $BuildMetadata.IsBuildServer )
        {
            $patch = $BuildMetadata.BuildNumber
        }
        $today = Get-Date
        $semVersion = New-Object 'SemVersion.SemanticVersion' $today.Year,$today.ToString('MMdd'),$patch,$Prerelease
    }

    $buildInfo = '{0}.{1}' -f $env:USERNAME,$env:COMPUTERNAME
    if( $BuildMetadata.IsBuildServer )
    {
        $branch = $BuildMetadata.ScmBranch
        $branch = $branch -replace '[^A-Za-z0-9-]','-'
        $commitID = $BuildMetadata.ScmCommitID.Substring(0,7)
        $buildInfo = '{0}.{1}.{2}' -f $BuildMetadata.BuildNumber,$branch,$commitID
    }

    if( -not $Prerelease )
    {
        $Prerelease = $semVersion.Prerelease
    }

    return New-Object 'SemVersion.SemanticVersion' $semVersion.Major,$semVersion.Minor,$semVersion.Patch,$Prerelease,$buildInfo
}
