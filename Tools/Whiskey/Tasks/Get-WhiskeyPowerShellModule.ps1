function Get-WhiskeyPowerShellModule 
{
    <#
    .SYNOPSIS
    Downloads a PowerShell module.
    
    .DESCRIPTION
    The `GetPowerShellModule` task downloads a PowerShell module  and saves it into a `Modules` directory in the build root. Use the `Name` property to specify the name of the module to download. By default, it downloads the most recent version of the module. Use the `Version` property to download a specific version.

    The module is downloaded from any of the repositories that are configured on the current machine. Those repositories must be trusted and initialized, otherwise the module will fail to download.

    ## Property

    * `Name` (mandatory): the name of the module to download.
    * `Version`: the version number to download. The default behavior is to download the latest version. Wildcards allowed, e.g. use `2.*` to pin to major version `2`.

    .EXAMPLE

    ## Example 1

        Build:
        - GetPowerShellModule:
            Name: Whiskey

    This example demonstrates how to download the latest version of a PowerShell module. In this case, the latest version of Whiskey is downloaded and saved into the `.\Modules` directory in your build root.

    ## Example 2

        Build:
        - GetPowerShellModule:
            Name: Whiskey
            Version: "0.14.*"

    This example demonstrates how to pin to a specific version of a module. In this case, the latest `0.14.x` version will be downloaded. When version 0.15.0 comes out, you'll still download the latest `0.14.x` version.

    #>
    
    [CmdletBinding()]
    [Whiskey.Task("GetPowerShellModule",SupportsClean=$true, SupportsInitialize=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $TaskParameter['Name'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message "Please Add a Name Property for which PowerShell Module you would like to get."
    }
    $TaskParameter['Path'] = $TaskContext.BuildRoot

    if( -not $TaskParameter['Version'])
    {
        try
        {
            $TaskParameter['Version'] = Resolve-WhiskeyPowerShellModule -Name $TaskParameter['Name'] | Select-Object -ExpandProperty 'Version'
        }
        catch
        {
            Write-Error 'Cannot Find Version from PowerShell Module ''{0}''.' -f $TaskParameter['Name']
        }
    }

    if( $TaskContext.ShouldClean )
    {
        Uninstall-WhiskeyTool -ModuleName $TaskParameter['Name'] -BuildRoot $TaskContext.BuildRoot
        return
    }
    return Install-WhiskeyTool -ModuleName $TaskParameter['Name'] -Version $TaskParameter['Version'] -DownloadRoot $TaskContext.BuildRoot
}