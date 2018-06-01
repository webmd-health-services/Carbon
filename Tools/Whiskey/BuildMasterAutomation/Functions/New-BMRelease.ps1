
function New-BMRelease
{
    <#
    .SYNOPSIS
    Creates a new release for an application in BuildMaster.

    .DESCRIPTION
    The `New-BMRelease` function creates a release for an application in BuildMaster. It uses the BuildMaster [Release and Package Deployment API](http://inedo.com/support/documentation/buildmaster/reference/api/release-and-package).

    .EXAMPLE
    New-BMRelease -Session $session -Application 'BuildMasterAutomation' -Number '1.0' -Pipeline 'PowerShellModule'

    Demonstrates how to create a release using application/pipeline names. In this example, creates a `1.0` release for the `BuildMasterAutomation` application using the `PowerShellModule` pipeline.

    .EXAMPLE
    New-BMRelease -Session $session -Application 25 -Number '2.0' -Pipeline 3

    Demonstrates how to create a release using application/pipeline IDs. In this example, creates a `1.0` release for the application whose ID is `25` using the pipeline whose ID is `3`.

    .EXAMPLE
    New-BMRelease -Session $session -Application $app -Number '3.0' -Pipeline $pipeline

    Demonstrates how to create a release using application/pipeline objects. In this example, creates a `1.0` release for the application represented by the `$app` object (which must have either a `Application_Id` or `Application_Name` property that represent the ID and name of the application, respectively) using the pipeline represented by the `$pipeline` object (which must have either a `Pipeline_Id` or `Pipeline_Name` property that represent the ID and name of the pipeline, respectively).

    .EXAMPLE
    New-BMRelease -Session $session -Name 'BMA 1.0' -Application 'BuildMasterAutomation' -Number '1.0' -Pipeline 'PowerShellModule'

    Demonstrates how to create a release with a custom name. In this example, the release would be named `BMA 1.0`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that represents what BuildMaster instance to connect to and what API key to use. Use `New-BMSession` to create a session object.
        $Session,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [object]
        # The application where the release should be created. Can be:
        #
        # * The application's name.
        # * The application's ID.
        # * An application object with either an `Application_Id` or `Application_Name` property that represent the application's ID and name, respectively.
        $Application,

        [Parameter(Mandatory=$true)]
        [string]
        # The release number, e.g. 1, 2, 3, 1.0, 2.0, etc.
        $Number,

        [Parameter(Mandatory=$true)]
        [object]
        # The pipeline the release should use. Can be:
        #
        # * The pipeline's name.
        # * The pipeline's ID.
        # * A pipeline object with either a `Pipeline_Id` or `Pipeline_Name` property that represent the pipeline's ID and name, respectively.
        $Pipeline,

        [string]
        # The name of the release. By default, BuildMaster uses the release number, passed with the `Number` parameter.
        $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $parameters = @{
                            releaseNumber = $Number;
                            releaseName = $Name;
                       }
        
        $parameters | 
            Add-BMObjectParameter -Name 'application' -Value $Application -PassThru | 
            Add-BMObjectParameter -Name 'pipeline' -Value $Pipeline

        Invoke-BMRestMethod -Session $Session -Name 'releases/create' -Method Post -Parameter $parameters
    }
}
