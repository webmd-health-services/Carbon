
function Set-WhiskeyMSBuildConfiguration
{
    <#
    .SYNOPSIS
    Changes the configuration to use when running any MSBuild-based task/tool.

    .DESCRIPTION
    The `Set-WhiskeyMSBuildConfiguration` function sets the configuration to use when running any MSBuild-based task/tool (e.g. the `MSBuild`, `DotNetBuild`, `DotNetPublish`, etc.). Usually, the value should be set to either `Debug` or `Release`.

    Use `Get-WhiskeyMSBuildConfiguration` to get the current configuration.

    .EXAMPLE
    Set-WhiskeyMSBuildConfiguration -Context $Context -Value 'Release'

    Demonstrates how to set the configuration to use when running MSBuild tasks/tools.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        # The context of the build whose MSBuild configuration you want to set. Use `New-WhiskeyContext` to create a context.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The configuration to use.
        $Value
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $Context.MSBuildConfiguration = $Value
}