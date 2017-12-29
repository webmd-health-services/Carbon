function Uninstall-WhiskeyTool
{
    <#
    .SYNOPSIS
    Removes any specified artifacts of a tool previoulsy installed by the Whiskey module.

    .DESCRIPTION
    The `Uninstall-WhiskeyTool` function removes PowerShell modules or NuGet Packages previously installed in the Whiskey module. PowerShell modules are removed from the `Modules` direcory in your build root. NuGet packages are removed from the `packages` directory in your build root.
    
    Users of the `Whiskey` API typcially won't need to use this function. It is called by other `Whiskey` function so they have the tools they need.

    .EXAMPLE
    Uninstall-WhiskeyTool -ModuleName 'Pester'

    Demonstrates how to remove the `Pester` module from the default location.
        
    .EXAMPLE
    Uninstall-WhiskeyTool -NugetPackageName 'NUnit.Runners' -Version '2.6.4'

    Demonstrates how to uninstall a specific NuGet Package. In this case, NUnit Runners version 2.6.4 would be removed from the default location. 

    .EXAMPLE
    Uninstall-WhiskeyTool -ModuleName 'Pester' -Path $forPath

    Demonstrates how to remove a Pester module from a specified path location other than the default location. In this case, Pester would be removed from the directory pointed to by the $forPath variable.
    
    .EXAMPLE
    Uninstall-WhiskeyTool -ModuleName 'Pester' -DownloadRoot $Root

    Demonstrates how to remove a Pester module from a DownloadRoot. In this case, Pester would be removed from `$Root\Modules`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='PowerShell')]
        [string]
        # The name of the PowerShell module to uninstall.
        $ModuleName,

        [Parameter(Mandatory=$true,ParameterSetName='NuGet')]
        [string]
        # The name of the NuGet package to uninstall.
        $NuGetPackageName,

        [String]
        # The version of the package to uninstall. Must be a three part number, i.e. it must have a MAJOR, MINOR, and BUILD number.
        $Version,

        [Parameter(Mandatory=$true)]
        [string]
        # The build root where the build is currently running. Tools are installed here.
        $BuildRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -eq 'PowerShell' )
    {
        $module = Resolve-WhiskeyPowerShellModule -Name $ModuleName -Version $Version
        if( -not $module )
        {
            return
        }
        $modulesRoot = Join-Path -Path $BuildRoot -ChildPath 'Modules'
        #Remove modules saved by either PowerShell4 or PowerShell5
        $moduleRoots = @( ('{0}\{1}' -f $ModuleName, $module.Version), ('{0}' -f $ModuleName)  )
        foreach ($item in $moduleRoots)
        {
            $removeModule = (Join-Path -Path $modulesRoot -ChildPath $item )
            if( Test-Path -Path $removeModule -PathType Container )
            {
                Remove-Item $removeModule -Recurse -Force
                return
            }
        }
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'NuGet' )
    {
        $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath '..\bin\NuGet.exe' -Resolve
        $Version = Resolve-WhiskeyNuGetPackageVersion -NuGetPackageName $NuGetPackageName -Version $Version -NugetPath $nugetPath
        if( -not $Version )
        {
            return
        }
        $packagesRoot = Join-Path -Path $BuildRoot -ChildPath 'packages'
        $nuGetRootName = '{0}.{1}' -f $NuGetPackageName,$Version
        $nuGetRoot = Join-Path -Path $packagesRoot -ChildPath $nuGetRootName
        
        if( (Test-Path -Path $nuGetRoot -PathType Container) )
        {
            Remove-Item -Path $nuGetRoot -Recurse -Force
        }
    }
}
