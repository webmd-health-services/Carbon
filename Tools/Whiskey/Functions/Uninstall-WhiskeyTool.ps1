function Uninstall-WhiskeyTool
{
    <#
    .SYNOPSIS
    Removes a tool installed with `Install-WhiskeyTool`.

    .DESCRIPTION
    The `Uninstall-WhiskeyTool` function removes tools that were installed with `Install-WhiskeyTool`. It removes PowerShell modules, NuGet packages, Node, Node modules, and .NET Core SDKs that Whiskey installs into your build root. PowerShell modules are removed from the `Modules` direcory. NuGet packages are removed from the `packages` directory. Node and node modules are removed from the `.node` directory. The .NET Core SDK is removed from the `.dotnet` directory.

    When uninstalling a Node module, its name should be prefixed with `NodeModule::`, e.g. `NodeModule::rimraf`.
    
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

    .EXAMPLE
    Uninstall-WhiskeyTool -Name 'Node' -InstallRoot $TaskContext.BuildRoot

    Demonstrates how to uninstall Node from the `.node` directory in your build root.

    .EXAMPLE
    Uninstall-WhiskeyTool -Name 'NodeModule::rimraf' -InstallRoot $TaskContext.BuildRoot

    Demonstrates how to uninstall the `rimraf` Node module from the `.node\node_modules` directory in your build root.

    .EXAMPLE
    Uninstall-WhiskeyTool -Name 'DotNet' -InstallRoot $TaskContext.BuildRoot

    Demonstrates how to uninstall the .NET Core SDK from the `.dotnet` directory in your build root.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='Tool')]
        [string]
        # The name of the tool to uninstall. Currently only Node is supported.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='Tool')]
        [string]
        # The directory where the tool should be uninstalled from.
        $InstallRoot,

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

        [Parameter(Mandatory=$true,ParameterSetName='PowerShell')]
        [Parameter(Mandatory=$true,ParameterSetName='NuGet')]
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
    elseif( $PSCmdlet.ParameterSetName -eq 'Tool' )
    {
        $provider,$Name = $Name -split '::'
        if( -not $Name )
        {
            $Name = $provider
            $provider = ''
        }

        switch( $provider )
        {
            'NodeModule'
            {
                # Don't do anything. All node modules require the Node tool to also be defined so they'll get deleted by the Node deletion.
            }
            default
            {
                switch( $Name )
                {
                    'Node'
                    {
                        $dirToRemove = Join-Path -Path $InstallRoot -ChildPath '.node'
                        Remove-WhiskeyFileSystemItem -Path $dirToRemove
                    }
                    'DotNet'
                    {
                        $dotnetToolRoot = Join-Path -Path $InstallRoot -ChildPath '.dotnet'
                        Remove-WhiskeyFileSystemItem -Path $dotnetToolRoot
                    }
                    default
                    {
                        throw ('Unknown tool ''{0}''. The only supported tools are ''Node'' and ''DotNet''.' -f $Name)
                    }
                }
            }
        }
    }
}
