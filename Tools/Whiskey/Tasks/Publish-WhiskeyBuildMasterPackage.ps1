
function Publish-WhiskeyBuildMasterPackage
{
    <#
    .SYNOPSIS
    Creates and deploys a release package in BuildMaster.

    .DESCRIPTION
    The `PublishBuildMasterPackage` task creates a release package in BuildMaster. By default, it also starts a deployment of the package to the first stage of the release's pipeline. It uses the `New-BMPackage` function from the `BuildMasterAutomation` module to create the package. It uses the `Publish-BMReleasePackage` to start the deployment.

    Set the `ApplicationName` property to the name of the application in BuildMaster where the package should be published. Set the `ReleaseName` property to the name of the release in BuildMaster where the package should be published. Set the `Uri` property to the base URI to BuildMaster. Set the `ApiKeyID` property to the ID of the API key to use when publishing the package to BuildMaster. Use the `Add-WhiskeyApiKey` to add your API key.

    Set the `DeployTo` property to map an SCM branch to its corresponding BuildMaster release where packages should be created and deployed. `BranchName` and `ReleaseName` are required. The task will fail if the current branch is not mapped to an existing release. `StartAtStage` and `SkipDeploy` are optional. By default, a deployment will start at the first stage of a release pipeline and will not be skipped.

    ## Property

    * `ApplicationName` (mandatory): the name of the application in BuildMaster where the package should be published.
    * `ReleaseName` (mandatory): the name of the release in BuildMaster where the package should be published.
    * `Uri` (mandatory): the BuildMaster URI where the package should be published.
    * `ApiKeyID` (mandatory): the ID of the API key to use when publishing the package to BuildMaster. Use the `Add-WhiskeyApiKey` to add your API key.
    * `PackageVariable`: the variables to configure in BuildMaster unique to this package. By default, the package will not have any package-level variables.
    * `PackageName`: the name of the package that will be created in BuildMaster. By default, the package will be named "MajorVersion.MinorVersion.PatchVersion"
    * `StartAtStage`: the stage of the release pipeline where the package should start its deployment. By default, the package will be released to the first stage of the pipeline.
    * `SkipDeploy`: the release package should be created, but not automatically deployed. By default, the package deployment will be started.
    
    ## Examples

    ### Example 1

        Publish:
        - PublishBuildMasterPackage:
            ApplicationName: TestApplication
            ReleaseName: ProdRelease
            Uri: https://buildmaster.example.com
            ApiKeyID: buildmaster.example.com
            
    Demonstrates the minimal configuration needed to create and deploy a package. In this case, a package will be created on the `ProdRelease` release of the `TestApplication` application at `https://buildmaster.example.com` using the API key with the `buildmaster.example.com` ID. The package will be deployed to the first stage of the release's pipeline.

    ### Example 2

        Publish:
        - PublishBuildMasterPackage:
            ApplicationName: TestApplication
            ReleaseName: ProdRelease
            Uri: https://buildmaster.example.com
            ApiKeyID: buildmaster.example.com
            PackageName: TestPackage
            StartAtStage: TestStaging
            
    In this case, the package will be named `TestPackage` instead of the default "MajorVersion.MinorVersion.PatchVersion". The package will be deployed to `TestStaging` stage of the `ProdRelease` release's pipeline.

    ### Example 3

        Publish:
        - PublishBuildMasterPackage:
            ApplicationName: TestApplication
            ReleaseName: ProdRelease
            Uri: https://buildmaster.example.com
            ApiKeyID: buildmaster.example.com
            SkipDeploy: true
            
    In this case, a package will be created on the `ProdRelease` release of the `TestApplication` application. The package will not be deployed because the `SkipDeploy` property is defined.
    #>
    [CmdletBinding()]
    [Whiskey.Task("PublishBuildMasterPackage")]
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
