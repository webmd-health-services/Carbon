
function Get-BMPackage
{
    <#
    .SYNOPSIS
    Gets a package from BuildMaster.

    .DESCRIPTION
    The `Get-BMPackage` function gets a package from BuildMaster. With no parameters, it returns all packages. To get all the packages that are part of a release, pass a release object or ID to the `Release` property (a release object must have an `id` or `Release_Id` property). To get a specific package, pass a package object or ID to the `Package` property (a package object must have an `id` or `Package_Id` property).

    This function uses BuildMaster's "Release & Package Deployment" API. When creating a BuildMaster session (using the `New-BMSession` function), the API key you use must have access to that API.

    .EXAMPLE
    Get-BMPackage -Session $session

    Demonstrates how to get all packages.

    .EXAMPLE
    Get-BMPackage -Session $session -Package $package

    Demonstrates how to get a specific package using a package object. The package object must have an `id` or `Package_Id` property.

    .EXAMPLE
    Get-BMPackage -Session $session -Package 500

    Demonstrates how to get a specific package using its ID.

    .EXAMPLE
    Get-BMPackage -Session $session -Release $release

    Demonstrates how to get all the packages that are part of a release using a release object. The release object must have an `id` or `Release_Id` property.

    .EXAMPLE
    Get-BMPackage -Session $session -Release 438

    Demonstrates how to get all the packages that are part of a release using the release's ID.
    #>
    [CmdletBinding(DefaultParameterSetName='AllPackages')]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A object that represents what instance of BuildMaster to connect to. Use the `New-BMSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true,ParameterSetName='SpecificPackage')]
        [object]
        # The package to get. Can be:
        #
        # * A package object with a `Package_Id` or `id` property.
        # * A package ID (as an integer)
        $Package,

        [Parameter(Mandatory=$true,ParameterSetName='ReleasePackages')]
        [object]
        # The release whose packages to get. Gets all the packages that are part of this release.
        #
        # * A release object with a `Release_Id` or `id` property.
        # * A release ID (as an integer)
        $Release
    )

    Set-StrictMode -Version 'Latest'

    $parameter = $null
    if( $PSCmdlet.ParameterSetName -eq 'SpecificPackage' )
    {
        $parameter = @{ } | Add-BMObjectParameter -Name 'package' -Value $Package -PassThru
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'ReleasePackages' )
    {
        $parameter = @{ } | Add-BMObjectParameter -Name 'release' -Value $Release -PassThru
    }

    $parameterParam = @{ }
    if( $parameter )
    {
        $parameterParam['Parameter'] = $parameter
    }

    Invoke-BMRestMethod -Session $Session -Name 'releases/packages' @parameterParam |
        Where-Object {
            # There's a bug in BuildMaster's API that returns packages for multiple releases. We don't want this. 
            if( $PSCmdlet.ParameterSetName -eq 'ReleasePackages' )
            {
                return $_.releaseId -eq $parameter.releaseId
            }
            return $true
        }
}
