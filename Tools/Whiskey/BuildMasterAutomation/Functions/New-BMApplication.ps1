
function New-BMApplication
{
    <#
    .SYNOPSIS
    Creates an application in BuildMaster.

    .DESCRIPTION
    The `New-BMApplication` function creates an application in BuildMaster. This function uses the native BuildMaster API, which can change without notice between releases. Only a name is required to create an application. The name must be unique and not in use.

    These parameters are also available:

    * `ReleaseNumberScheme`: sets the release number scheme to use when you create a new release for the application. Options are `MajorMinorRevision`, `MajorMinor`, or `DateBased`.
    * `BuildNumberScheme`: sets the build number scheme to use when creating new packages/builds for an application. Options are `Unique`, `Sequential`, `DateBased`.
    * `AllowMultipleActiveBuilds`: a flag that indicates if the application is allowed to have multiple active builds.

    .EXAMPLE
    New-BMApplication -Session $session -Name 'MyNewApplication'

    Demonstrates the simplest way to create an application. In this example, a `MyNewApplication` application will be created and all its fields set to BuildMaster's default values.

    .EXAMPLE
    New-BMApplication -Session $session -Name 'MyNewApplication' -ReleaseNumberSchemeName MajorMinor -BuildNumberSchemeName Sequential -AllowMultipleActiveBuilds

    This example demonstrates all the fields you can set when creating a new application. In this example, the new application will be called `MyNewApplication`, its release number scheme will be `MajorMinor`, its build number schema will be `Sequential`, it will allow multiple active releases, and it will allow multiple active builds.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the application.
        $Name,

        [string]
        [ValidateSet('MajorMinorRevision','MajorMinor','DateBased')]
        # The name of the release number scheme. Should be one of:
        #
        # * `MajorMinorRevision`
        # * `MajorMinor`
        # * `DateBased`
        $ReleaseNumberSchemeName,

        [string]
        [ValidateSet('Unique','Sequential','DateTimeBased')]
        # The name of the build number scheme. Should be one of:
        #
        # * `Unique`
        # * `Sequential`
        # * `DateTimeBased`
        $BuildNumberSchemeName,

        [Switch]
        # Allow multiple active builds.
        $AllowMultipleActiveBuilds,

        [string]
        # The application group to assign. By default, the application will be ungrouped.
        $ApplicationGroupId
    )

    Set-StrictMode -Version 'Latest'

    $parameters = @{
                        'Application_Name' = $Name;
                    }
    if( $ReleaseNumberSchemeName )
    {
        $parameters['ReleaseNumber_Scheme_Name'] = $ReleaseNumberSchemeName;
    }

    if( $BuildNumberSchemeName )
    {
        $parameters['BuildNumber_Scheme_Name'] = $BuildNumberSchemeName;
    }

    if( $AllowMultipleActiveBuilds )
    {
        $parameters['AllowMultipleActiveBuilds_Indicator'] = $true;
    }

    if( $ApplicationGroupId )
    {
        $parameters['ApplicationGroup_Id'] = $ApplicationGroupId
    }
    
    $appID = Invoke-BMNativeApiMethod -Session $Session -Name 'Applications_CreateApplication' -Parameter $parameters
    if( -not $appID )
    {
        return
    }

    Invoke-BMNativeApiMethod -Session $Session -Name 'Applications_GetApplication' -Parameter @{ 'Application_Id' = $appID } |
        Select-Object -ExpandProperty 'Applications_Extended'
}