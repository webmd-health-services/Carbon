
function Install-WhiskeyTool
{
    <#
    .SYNOPSIS
    Downloads and installs tools needed by the Whiskey module.

    .DESCRIPTION
    The `Install-WhiskeyTool` function downloads and installs PowerShell modules or NuGet Packages needed by functions in the Whiskey module. PowerShell modules are installed to a `Modules` directory in your build root. A `DirectoryInfo` object for the downloaded tool's directory is returned.
    
    Users of the `Whiskey` API typcially won't need to use this function. It is called by other `Whiskey` function so they ahve the tools they need.

    .EXAMPLE
    Install-WhiskeyTool -ModuleName 'Pester'

    Demonstrates how to install the most recent version of the `Pester` module.

    .EXAMPLE
    Install-WhiskeyTool -ModuleName 'Pester' -Version 3

    Demonstrates how to instals the most recent version of a specific major version of a module. In this case, Pester version 3.6.4 would be installed (which is the most recent 3.x version of Pester as of this writing).
    
    .EXAMPLE
    Install-WhiskeyTool -NugetPackageName 'NUnit.Runners' -version '2.6.4'

    Demonstrates how to install a specific version of a NuGet Package. In this case, NUnit Runners version 2.6.4 would be installed. 

    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='PowerShell')]
        [string]
        # The name of the PowerShell module to download.
        $ModuleName,

        [Parameter(Mandatory=$true,ParameterSetName='NuGet')]
        [string]
        # The name of the NuGet package to download.
        $NuGetPackageName,

        [Parameter(ParameterSetName='NuGet')]
        [Parameter(ParameterSetName='PowerShell')]
        [string]
        # The version of the package to download. Must be a three part number, i.e. it must have a MAJOR, MINOR, and BUILD number.
        $Version,

        [Parameter(Mandatory=$true)]
        [string]
        # The root directory where the tools should be downloaded. The default is your build root.
        #
        # PowerShell modules are saved to `$DownloadRoot\Modules`.
        #
        # NuGet packages are saved to `$DownloadRoot\packages`.
        $DownloadRoot
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( $PSCmdlet.ParameterSetName -eq 'PowerShell' )
    {
        $modulesRoot = Join-Path -Path $DownloadRoot -ChildPath 'Modules'
        New-Item -Path $modulesRoot -ItemType 'Directory' -ErrorAction Ignore | Out-Null

        $expectedPath = Join-Path -Path $modulesRoot -ChildPath $ModuleName

        if( (Test-Path -Path $expectedPath -PathType Container) )
        {
            Resolve-Path -Path $expectedPath | Select-Object -ExpandProperty 'ProviderPath'
            return
        }

        Invoke-Command -ScriptBlock {
                                        $VerbosePreference = 'SilentlyContinue'
                                        Import-Module -Name 'PackageManagement'
                                    }

        $Version = Resolve-WhiskeyPowerShellModuleVersion -ModuleName $ModuleName -Version $Version
        if( -not $Version )
        {
            return
        }

        Save-Module -Name $ModuleName -RequiredVersion $Version -Path $modulesRoot -ErrorVariable 'errors' -ErrorAction $ErrorActionPreference

        if( -not (Test-Path -Path $expectedPath -PathType Container) )
        {
            Write-Error -Message ('Failed to download {0} {1} from the PowerShell Gallery. Either the {0} module does not exist, or it does but version {1} does not exist. Browse the PowerShell Gallery at https://www.powershellgallery.com/' -f $ModuleName,$Version)
        }

        return $expectedPath
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'NuGet' )
    {        
        $nugetPath = Join-Path -Path $PSScriptRoot -ChildPath '..\bin\NuGet.exe' -Resolve
        $packagesRoot = Join-Path -Path $DownloadRoot -ChildPath 'packages'
        $version = Resolve-WhiskeyNuGetPackageVersion -NuGetPackageName $NuGetPackageName -Version $Version -NugetPath $nugetPath
        if( -not $Version )
        {
            return
        }

        $nuGetRootName = '{0}.{1}' -f $NuGetPackageName,$Version
        $nuGetRoot = Join-Path -Path $packagesRoot -ChildPath $nuGetRootName
        Set-Item -Path 'env:EnableNuGetPackageRestore' -Value 'true'
        if( -not (Test-Path -Path $nuGetRoot -PathType Container) )
        {
           & $nugetPath install $NuGetPackageName -version $Version -OutputDirectory $packagesRoot | Write-CommandOutput -Description ('Nuget.exe install')
        }
        return $nuGetRoot
    }
} 
