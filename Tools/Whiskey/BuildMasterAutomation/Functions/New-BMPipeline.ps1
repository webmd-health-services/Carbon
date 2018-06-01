
function New-BMPipeline
{
    <#
    .SYNOPSIS
    Creates a new pipeline in BuildMaster.

    .DESCRIPTION
    The `New-BMPipeline` function creates a new pipeline in BuildMaster and retuns an object representing the new pipeline. In order to deploy an application, you must create a release for that application. Each release gets assigned a pipeline, which are the set of steps to do when releasing and deploying. Pipelines can belong to a specific application or shared between applications.

    The pipeline is created with no stages. The following settings are enabled:

    * Enforce pipeline stage order for deployments

    The following settings are disabled:

    * Cancel earlier (lower-sequenced) releases that are still active and have not yet been deployed.
    * Create a new release by incrementing the final part after a release has been deployed.
    * Mark the release and package as deployed once it reaches the final stage.

    This function uses [BuildMaster's native API](http://inedo.com/support/documentation/buildmaster/reference/api/native).

    .EXAMPLE
    New-BMPipeline -Session $session -Name 'Powershell Module'

    Demonstrates how to create a new pipeline that is not used by any applications. In this example a pipeline named `PowerShell Module` will be created.

    .EXAMPLE
    New-BMPipeline -Session $session -Name 'PowerShell Module' -Application $app

    Demonstrates how to create a new pipeline and assign it to a specific application. In this example, the pipeline will be called `PowerShell Module` and it will be assigned to the `$app` application.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # An object that represents the instance of BuildMaster to connect to. Use the `New-BMSession` function to creates a session object.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the pipeline.
        $Name,

        [object]
        # The application to assign the pipeline to. Can be:
        #
        # * An application object with `Application_Id`, `id`, `Application_Name`, or `name` properties.
        # * An application ID (must be an integer)
        # * An applicatoin name (must be a string)
        $Application,

        [string]
        # The background color BuildMaster should use when displaying the pipeline's name in the UI. Should be a CSS hexadecimal color, e.g. `#ffffff`
        $Color,

        [string[]]
        # Stage configuration for the pipeline. Should be an array of `<Inedo.BuildMaster.Pipelines.PipelineStage>` XML elements. 
        $Stage
    )

    Set-StrictMode -Version 'Latest'

    $pipelineParams = @{
                        'Pipeline_Name' = $Name;
                        'Pipeline_Configuration' = @"
<Inedo.BuildMaster.Pipelines.Pipeline Assembly="BuildMaster">
  <Properties Name="Standard" Description="" EnforceStageSequence="True">
     <Stages>
        $( $Stage -join [Environment]::NewLine )
     </Stages>
     <PostDeploymentOptions>
        <Inedo.BuildMaster.Pipelines.PipelinePostDeploymentOptions Assembly="BuildMaster">
           <Properties CreateRelease="False" CancelReleases="False" DeployRelease="False" />
        </Inedo.BuildMaster.Pipelines.PipelinePostDeploymentOptions>
     </PostDeploymentOptions>
  </Properties>
</Inedo.BuildMaster.Pipelines.Pipeline>
"@;
                        'Active_Indicator' = $true;
                   }
    if( $Application )
    {
        $pipelineParams | Add-BMObjectParameter -Name 'application' -Value $Application
    }

    if( $Color )
    {
        $pipelineParams['Pipeline_Color'] = $Color
    }

    $pipelineId = Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_CreatePipeline' -Parameter $pipelineParams
    if( $pipelineId )
    {
        Invoke-BMNativeApiMethod -Session $session -Name 'Pipelines_GetPipeline' -Parameter @{ 'Pipeline_Id' = $pipelineId }    
    }
}