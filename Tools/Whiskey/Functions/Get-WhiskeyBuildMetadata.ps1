
function Get-WhiskeyBuildMetadata
{
    <#
    SYNOPSIS
    Gets metadata about the current build.

    .DESCRIPTION
    The `Get-WhiskeyBuildMetadata` function gets information about the current build. It is exists to hide what CI server the current build is running under. It returns an object with the following properties:

    * `ScmUri`: the URI to the source control repository used in this build.
    * `BuildNumber`: the build number of the current build. This is the incrementing number most CI servers used to identify a build of a specific job.
    * `BuildID`: this unique identifier for this build. Usually, this is used by CI servers to distinguish this build from builds across all jobs.
    * `ScmCommitID`: the full ID of the commit that is being built.
    * `ScmBranch`: the branch name of the commit that is being built.
    * `JobName`: the name of the job that is running the build.
    * `BuildUri`: the URI to this build's results.

    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    function Get-EnvironmentVariable
    {
        param(
            $Name
        )

        Get-Item -Path ('env:{0}' -f $Name) | Select-Object -ExpandProperty 'Value'
    }

    $buildInfo = New-WhiskeyBuildMetadataObject

    if( (Test-Path -Path 'env:JENKINS_URL') )
    {
        $buildInfo.BuildNumber = Get-EnvironmentVariable 'BUILD_NUMBER'
        $buildInfo.BuildID = Get-EnvironmentVariable 'BUILD_TAG'
        $buildInfo.BuildUri = Get-EnvironmentVariable 'BUILD_URL'
        $buildInfo.JobName = Get-EnvironmentVariable 'JOB_NAME'
        $buildInfo.JobUri = Get-EnvironmentVariable 'JOB_URL'
        $buildInfo.ScmUri = Get-EnvironmentVariable 'GIT_URL'
        $buildInfo.ScmCommitID = Get-EnvironmentVariable 'GIT_COMMIT'
        $buildInfo.ScmBranch = Get-EnvironmentVariable 'GIT_BRANCH'
        $buildInfo.ScmBranch = $buildInfo.ScmBranch -replace '^origin/',''
        $buildInfo.BuildServer = [Whiskey.BuildServer]::Jenkins
    }
    elseif( (Test-Path -Path 'env:APPVEYOR') )
    {
        $buildInfo.BuildNumber = Get-EnvironmentVariable 'APPVEYOR_BUILD_NUMBER'
        $buildInfo.BuildID = Get-EnvironmentVariable 'APPVEYOR_BUILD_ID'
        $accountName = Get-EnvironmentVariable 'APPVEYOR_ACCOUNT_NAME'
        $projectSlug = Get-EnvironmentVariable 'APPVEYOR_PROJECT_SLUG'
        $projectUri = 'https://ci.appveyor.com/project/{0}/{1}' -f $accountName,$projectSlug
        $buildVersion = Get-EnvironmentVariable 'APPVEYOR_BUILD_VERSION'
        $buildUri = '{0}/build/{1}' -f $projectUri,$buildVersion
        $buildInfo.BuildUri = $buildUri
        $buildInfo.JobName = Get-EnvironmentVariable 'APPVEYOR_PROJECT_NAME'
        $buildInfo.JobUri = $projectUri
        $baseUri = ''
        switch( (Get-EnvironmentVariable 'APPVEYOR_REPO_PROVIDER') )
        {
            'gitHub'
            {
                $baseUri = 'https://github.com'
            }
            default
            {
                Write-Error -Message ('Unsupported AppVeyor source control provider ''{0}''. If you''d like us to add support for this provider, please submit a new issue at https://github.com/webmd-health-services/Whiskey/issues. Copy/paste your environment variables from this build''s output into your issue.' -f $_)
            }
        }
        $repoName = Get-EnvironmentVariable 'APPVEYOR_REPO_NAME'
        $buildInfo.ScmUri = '{0}/{1}.git' -f $baseUri,$repoName
        $buildInfo.ScmCommitID = Get-EnvironmentVariable 'APPVEYOR_REPO_COMMIT'
        $buildInfo.ScmBranch = Get-EnvironmentVariable 'APPVEYOR_REPO_BRANCH'
        $buildInfo.BuildServer = [Whiskey.BuildServer]::AppVeyor
    }
    elseif( (Test-Path -Path 'env:TEAMCITY_BUILD_PROPERTIES_FILE') )
    {
        function Import-TeamCityProperty
        {
            [OutputType([hashtable])]
            param(
                $Path
            )

            $properties = @{ }
            Get-Content -Path $Path |
                Where-Object { $_ -match '^([^=]+)=(.*)$' } |
                ForEach-Object { $properties[$Matches[1]] = $Matches[2] -replace '\\(.)','$1' }
            $properties
        }

        $buildInfo.BuildNumber = Get-EnvironmentVariable 'BUILD_NUMBER'
        $buildInfo.ScmCommitID = Get-EnvironmentVariable 'BUILD_VCS_NUMBER'
        $buildPropertiesPath = Get-EnvironmentVariable 'TEAMCITY_BUILD_PROPERTIES_FILE'

        $buildProperties = Import-TeamCityProperty -Path $buildPropertiesPath
        $buildInfo.BuildID = $buildProperties['teamcity.build.id']
        $buildInfo.JobName = $buildProperties['teamcity.buildType.id']
        
        $configProperties = Import-TeamCityProperty -Path $buildProperties['teamcity.configuration.properties.file']
        $buildInfo.ScmBranch = $configProperties['teamcity.build.branch'] -replace '^refs/heads/',''
        $buildInfo.ScmUri = $configProperties['vcsroot.url']
        $buildInfo.BuildServer = [Whiskey.BuildServer]::TeamCity

        $serverUri = $configProperties['teamcity.serverUrl']
        $buildInfo.JobUri = '{0}/viewType.html?buildTypeId={1}' -f $serverUri,$buildInfo.JobName
        $buildInfo.BuildUri = '{0}/viewLog.html?buildId={1}&buildTypeId={2}' -f $serverUri,$buildInfo.BuildID,$buildInfo.JobName
    }

    return $buildInfo
}

