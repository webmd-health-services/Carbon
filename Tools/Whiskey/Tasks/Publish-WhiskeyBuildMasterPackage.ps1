
function Publish-WhiskeyBuildMasterPackage
{
    [CmdletBinding()]
    [Whiskey.Task("PublishBuildMasterPackage")]
    [Whiskey.RequiresTool('PowerShellModule::BuildMasterAutomation','BuildMasterAutomationPath',Version='0.5.*',VersionParameterName='BuildMasterAutomationVersion')]
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

    Import-WhiskeyPowerShellModule -Name 'BuildMasterAutomation'
    
    $applicationName = $TaskParameter['ApplicationName']
    if( -not $applicationName )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''ApplicationName'' is mandatory. It must be set to the name of the application in BuildMaster where the package should be published.')
    }
    
    $releaseName = $TaskParameter['ReleaseName']
    if( -not $releaseName )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''ReleaseName'' is mandatory. It must be set to the release name in the BuildMaster application where the package should be published.')
    }
    
    $buildmasterUri = $TaskParameter['Uri']
    if( -not $buildmasterUri )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''Uri'' is mandatory. It must be set to the BuildMaster URI where the package should be published.')
    }

    $apiKeyID = $TaskParameter['ApiKeyID']
    if( -not $apiKeyID )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''ApiKeyID'' is mandatory. It should be the ID of the API key to use when publishing the package to BuildMaster. Use the `Add-WhiskeyApiKey` to add your API key.')
    }
    
    $apiKey = Get-WhiskeyApiKey -Context $TaskContext -ID $TaskParameter['ApiKeyID'] -PropertyName 'ApiKeyID'
    $buildMasterSession = New-BMSession -Uri $TaskParameter['Uri'] -ApiKey $apiKey

    $version = $TaskContext.Version.SemVer2

    $variables = $TaskParameter['PackageVariable']

    $release = Get-BMRelease -Session $buildMasterSession -Application $applicationName -Name $releaseName -ErrorAction Stop
    if( -not $release )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Unable to create and deploy a release package in BuildMaster. Either the ''{0}'' application doesn''t exist or it doesn''t have a ''{1}'' release.' -f $applicationName,$releaseName)
    }

    $release | Format-List | Out-String | Write-WhiskeyVerbose -Context $TaskContext

    if( $TaskParameter['PackageName'] )
    {
        $packageName = $TaskParameter['PackageName']
    }
    else
    {
        $packageName = '{0}.{1}.{2}' -f $version.Major,$version.Minor,$version.Patch
    }
    
    $package = New-BMPackage -Session $buildMasterSession -Release $release -PackageNumber $packageName -Variable $variables -ErrorAction Stop
    $package | Format-List | Out-String | Write-WhiskeyVerbose -Context $TaskContext

    if( ConvertFrom-WhiskeyYamlScalar -InputObject $TaskParameter['SkipDeploy'] )
    {
        Write-WhiskeyVerbose -Context $TaskContext -Message ('Skipping deploy. SkipDeploy property is true')
    }
    else
    {
        $optionalParams = @{ 'Stage' = $TaskParameter['StartAtStage'] }
        
        $deployment = Publish-BMReleasePackage -Session $buildMasterSession -Package $package @optionalParams -ErrorAction Stop
        $deployment | Format-List | Out-String | Write-WhiskeyVerbose -Context $TaskContext
    }
}
