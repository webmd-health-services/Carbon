
function New-BMPackage
{
    <#
    .SYNOPSIS
    Creates a new package for a release.

    .DESCRIPTION
    The `New-BMPackage` creates a new package/version/build of an application. In order to deploy an application, the application must have a release. Then you create packages in that release, and each package is then deployed using the release's pipeline.

    .EXAMPLE
    New-BMPackage -Session $session -Release $release

    Demonstrates how to create a new package in the `$release` release. BuildMaster detects what application based on the release (since releases are always tied to applications). Verion numbers and package numbers are incremented and handled based on the release settings.

    The `$release` parameter can be:

    * A release object with an `id` property.
    * A release ID integer.

    .EXAMPLE
    New-BMPackage -Session $session -ReleaseName '53' -Application $applicatoin

    Demonstrates how to create a new package by using the release's name. Since release names are only unique within an application, you must also specify the application via the `Application` parameter.

    .EXAMPLE
    New-BMPackage -Session $session -Release $release -PacakgeName '56.develop' -Variable @{ ProGetPackageName = '17.1.54+developer.deadbee' }

    Demonstrates how to create a release with a specific name, `56.develop`, and with a package-level variable, `ProGetPackageName`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that represents the instance of BuildMaster to connect to. Use the `New-BMSession` function to creates a session object.
        $Session,

        [Parameter(Mandatory=$true,ParameterSetName='ByReleaseID')]
        [object]
        # The release where the package should be created. Can be:
        #
        # * a release object with an `id` property 
        # * the release ID as an integer
        $Release,

        [Parameter(Mandatory=$true,ParameterSetName='ByReleaseNumber')]
        [string]
        # The release number where the package should be created. Release numbers are unique within an application and can be duplicated between applications. If you use this parameter to identify the release, you must also provide a value for the `Application` parameter.
        $ReleaseNumber,

        [Parameter(Mandatory=$true,ParameterSetName='ByReleaseNumber')]
        [object]
        # The application where the release identified by the `ReleaseNumber` parameter can be found. Can be:
        #
        # * An application object with a `Application_Id`, `id`, `Application_Name`, or `name` properties.
        # * The application ID as an integer.
        # * The application name as a string.
        $Application,

        [string]
        # The package number/name. If not provided, BuildMaster generates one based on the release settings.
        $PackageNumber,

        [hashtable]
        # Any package variables to set. Package variables are unique to each package.
        $Variable
    )

    Set-StrictMode -Version 'Latest'

    $parameters = @{ } 
    
    if( $PSCmdlet.ParameterSetName -eq 'ByReleaseID' )
    {
        $parameters | Add-BMObjectParameter -Name 'release' -Value $Release
    }
    else
    {
        $parameters['releaseNumber'] = $ReleaseNumber
        $parameters | Add-BMObjectParameter -Name 'application' -Value $Application
    }

    if( $PackageNumber )
    {
        $parameters['packageNumber'] = $PackageNumber
    }

    if( $Variable )
    {
        foreach( $key in $Variable.Keys )
        {
            $parameters[('${0}' -f $key)] = $Variable[$key]
        }
    }

    Invoke-BMRestMethod -Session $Session -Name 'releases/packages/create' -Parameter $parameters          
}