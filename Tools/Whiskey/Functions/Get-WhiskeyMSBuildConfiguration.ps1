
function Get-WhiskeyMSBuildConfiguration
{
    <#
    .SYNOPSIS
    Gets the configuration to use when running any MSBuild-based task/tool.

    .DESCRIPTION
    The `Get-WhiskeyMSBuildConfiguration` function gets the configuration to use when running any MSBuild-based task/tool (e.g. the `MSBuild`, `DotNetBuild`, `DotNetPublish`, etc.). By default, the value is `Debug` when the build is being run by a developer and `Release` when run by a build server.

    Use `Set-WhiskeyMSBuildConfiguration` to change the current configuration.

    .EXAMPLE
    Get-WhiskeyMSBuildConfiguration -Context $Context

    Gets the configuration to use when runinng an MSBuild-based task/tool
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The context of the current build.
        $Context
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $Context.MSBuildConfiguration )
    {
        $configuration = 'Debug'
        if( $Context.ByBuildServer )
        {
            $configuration = 'Release'
        }
        Set-WhiskeyMSBuildConfiguration -Context $Context -Value $configuration
    }
    return $Context.MSBuildConfiguration
}