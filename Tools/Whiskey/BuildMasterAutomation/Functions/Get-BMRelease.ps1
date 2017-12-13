
function Get-BMRelease
{
    <#
    .SYNOPSIS
    Gets the release for an application in BuildMaster.

    .DESCRIPTION
    The `Get-BMRelease` function gets releases in BuildMaster. It uses the [Release and Package Deployment API](http://inedo.com/support/documentation/buildmaster/reference/api/release-and-package). 

    To get a specific release, pass a release object, release ID, or release name to the `Release` parameter.

    To get all the releases for a specific application, pass an application object, application ID, or application name to the `Application` parameter. You can get a specific application's release by passing the release's name to the `Name` parameter.

    .EXAMPLE
    Get-BMRelease -Session $session -Release $release

    Demonstrates how to get a specific release by passing a release object to the `Release` parameter. The `Get-BMRelease` function looks for an `id` or `name` property on the object.

    .EXAMPLE
    Get-BMRelease -Session $session -Application $app

    Demonstrates how to get all the releases for an application by passing an application object to the `Application` parameter. The application object must have a`Application_Id`, `id`, `Application_Name`, or `name` properties.

    .EXAMPLE
    Get-BMRelease -Session $session -Application 34

    Demonstrates how to get all the releases for an application by passing its ID to the `Application` parameter. 

    .EXAMPLE
    Get-BMRelease -Session $session -Application 'BuildMasterAutomation'

    Demonstrates how to get all the releases for an application by passing its name to the `Application` parameter. 

    .EXAMPLE
    Get-BMRelease -Session $session -Application 'BuildMasterAutomation' -Name '4.1'

    Demonstrates how to get a specific release for an application by passing the release's name to the `Name` parameter.  In this example, the '4.1' release will be returned, if it exists.
    #>
    [CmdletBinding(DefaultParameterSetName='AllReleases')]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that contains the settings to use to connect to BuildMaster. Use `New-BMSession` to create session objects.
        $Session,

        [Parameter(Mandatory=$true,ValueFromPipeline=$true,ParameterSetName='ByRelease')]
        [object]
        # The release to get. You can pass:
        #
        # * A release object. It must have either an `id` or `name` property.
        # * The release ID as an integer.
        # * The release name as a string.
        $Release,

        [Parameter(Mandatory=$true,ParameterSetName='ByApplication')]
        [object]
        # The application whose releases to get. You can pass:
        #
        # * An application object. It must have `Application_Id`, `id`, `Application_Name`, or `name` properties.
        # * The application ID as an integer.
        # * The application name as a string.
        $Application,

        [string]
        # The name of the release to get. 
        $Name
    )

    process
    {
        Set-StrictMode -Version 'Latest'

        $parameter = @{ } 
        
        if( $PSCmdlet.ParameterSetName -eq 'ByRelease' )
        {
            $parameter | Add-BMObjectParameter -Name 'release' -Value $Release
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'ByApplication' )
        {
            $parameter | Add-BMObjectParameter -Name 'application' -Value $Application
        }

        if( $Name )
        {
            $parameter['releaseName'] = $Name
        }

        Invoke-BMRestMethod -Session $Session -Name 'releases' -Parameter $parameter
    }
}