
function Publish-BMReleasePackage
{
    <#
    .SYNOPSIS
    Deploys a release package in BuildMaster.

    .DESCRIPTION
    The `Publish-BMReleasePackage` deploys a release package in BuildMaster. The package is deployed using the pipeline assigned to the release the package is part of. This function uses BuildMaster's [Release and Package Deployment API](http://inedo.com/support/documentation/buildmaster/reference/api/release-and-package).

    Pass the package to deploy to the `Package` parameter. This can be a package object or a package ID (as an integer).

    To deploy a package, it must be part of a release that has a pipeline. That pipeline must have at least one stage and that stage must have a plan. If none of these conditions are met, you'll get no object back with no errors written.

    .EXAMPLE
    Publish-BMReleasePackage -Session $session -Package $package

    Demonstrates how to deploy a package by passing a package object to the `Package` parameter. This object must have an `id` or `pipeline_id` property.
    
    .EXAMPLE
    Publish-BMReleasePackage -Session $session -Package 383

    Demonstrates how to deploy a package by passing its ID to the `Package` parameter.

    .EXAMPLE
    Publish-BMReleasePackage -Session $session -Package $package -Stage $stage

    Demonstrates how to deploy a package to a specific stage of the release pipeline. By default, a package will deploy to the first stage of the assigned pipeline.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object representing the BuildMaster instance to connect to. Use the `New-BMSession` function to create a session object.
        $Session,

        [Parameter(Mandatory=$true)]
        [object]
        # The package to deploy. Can be:
        #
        # * A package object which has an `id` property.
        # * The package's ID, as an integer.
        $Package,
        
        [string]
        # The name of the pipeline stage where the package will be deployed.
        $Stage
    )

    Set-StrictMode -Version 'Latest'

    $parameters = @{} | Add-BMObjectParameter -Name 'package' -Value $Package -PassThru
    
    if( $Stage )
    {
        $parameters['toStage'] = $Stage
    }
    
    Invoke-BMRestMethod -Session $Session -Name 'releases/packages/deploy' -Parameter $parameters
}
