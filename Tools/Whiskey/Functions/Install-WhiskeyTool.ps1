
function Install-WhiskeyTool
{
    <#
    .SYNOPSIS
    Downloads and installs tools needed by the Whiskey module.

    .DESCRIPTION
    The `Install-WhiskeyTool` function downloads and installs PowerShell modules or NuGet Packages needed by functions in the Whiskey module. PowerShell modules are installed to a `Modules` directory in your build root. A `DirectoryInfo` object for the downloaded tool's directory is returned.

    `Install-WhiskeyTool` also installs tools that are needed by tasks. Tasks define the tools they need with a [Whiskey.RequiresTool()] attribute in the tasks function. Supported tools are 'Node', 'NodeModule', and 'DotNet'.

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
        [Parameter(Mandatory=$true,ParameterSetName='Tool')]
        [Whiskey.RequiresToolAttribute]
        # The attribute that defines what tool is necessary.
        $ToolInfo,

        [Parameter(Mandatory=$true,ParameterSetName='Tool')]
        [string]
        # The directory where you want the tools installed.
        $InstallRoot,

        [Parameter(Mandatory=$true,ParameterSetName='Tool')]
        [hashtable]
        # The task parameters for the currently running task.
        $TaskParameter,

        [Parameter(ParameterSetName='Tool')]
        [Switch]
        # Running in clean mode, so don't install the tool if it isn't installed.
        $InCleanMode,

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

        [Parameter(Mandatory=$true,ParameterSetName='NuGet')]
        [Parameter(Mandatory=$true,ParameterSetName='PowerShell')]
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

    $mutexName = $InstallRoot
    if( $DownloadRoot )
    {
        $mutexName = $DownloadRoot
    }
    # Back slashes in mutex names are reserved.
    $mutexName = $mutexName -replace '\\','/'
    $startedWaitingAt = Get-Date
    $startedUsingAt = Get-Date
    $installLock = New-Object 'Threading.Mutex' $false,$mutexName
    $DebugPreference = 'Continue'
    Write-Debug -Message ('[{0:yyyy-MM-dd HH:mm:ss}]  Process "{1}" is waiting for mutex "{2}".' -f (Get-Date),$PID,$mutexName)

    try
    {
        try
        {
            [void]$installLock.WaitOne()
        }
        catch [Threading.AbandonedMutexException]
        {
            Write-Debug -Message ('[{0:yyyy-MM-dd HH:mm:ss}]  Process "{1}" caught "{2}" exception waiting to acquire mutex "{3}": {4}.' -f (Get-Date),$PID,$_.Exception.GetType().FullName,$mutexName,$_)
            $Global:Error.RemoveAt(0)
        }

        $waitedFor = (Get-Date) - $startedWaitingAt
        Write-Debug -Message ('[{0:yyyy-MM-dd HH:mm:ss}]  Process "{1}" obtained mutex "{2}" in {3}.' -f (Get-Date),$PID,$mutexName,$waitedFor)
        $DebugPreference = 'SilentlyContinue'
        $startedUsingAt = Get-Date

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

            $whiskeyRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
            Start-Job -ScriptBlock {
                $moduleName = $using:ModuleName
                $version = $using:Version
                $modulesRoot = $using:modulesRoot
                $whiskeyRoot = $using:whiskeyRoot
                $expectedPath = $using:expectedPath

                Import-Module -Name (Join-Path -Path $whiskeyRoot -ChildPath 'Whiskey.psd1')
                Import-Module -Name (Join-Path -Path $whiskeyRoot -ChildPath 'PackageManagement' -Resolve)
                Import-Module -Name (Join-Path -Path $whiskeyRoot -ChildPath 'PowerShellGet' -Resolve)

                $module = Resolve-WhiskeyPowerShellModule -Name $moduleName -Version $version
                if( -not $module )
                {
                    return
                }
                
                Save-Module -Name $moduleName -RequiredVersion $module.Version -Repository $module.Repository -Path $modulesRoot -ErrorVariable 'errors' -ErrorAction $using:ErrorActionPreference

                if( -not (Test-Path -Path $expectedPath -PathType Container) )
                {
                    Write-Error -Message ('Failed to download {0} {1} from the PowerShell Gallery. Either the {0} module does not exist, or it does but version {1} does not exist. Browse the PowerShell Gallery at https://www.powershellgallery.com/' -f $moduleName,$version)
                }

                return $expectedPath

            } | Wait-Job | Receive-Job
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
               & $nugetPath install $NuGetPackageName -version $Version -outputdirectory $packagesRoot | Write-CommandOutput -Description ('nuget.exe install')
            }
            return $nuGetRoot
        }
        elseif( $PSCmdlet.ParameterSetName -eq 'Tool' )
        {
            $provider,$name = $ToolInfo.Name -split '::'
            if( -not $name )
            {
                $name = $provider
                $provider = ''
            }

            $nodeRoot = Join-Path -Path $InstallRoot -ChildPath '.node'
            $nodePath = Join-Path -Path $nodeRoot -ChildPath 'node.exe'

            $version = $TaskParameter[$ToolInfo.VersionParameterName]
            if( -not $version )
            {
                $version = $ToolInfo.Version
            }

            switch( $provider )
            {
                'NodeModule'
                {

                    $moduleRoot = Install-WhiskeyNodeModule -Name $name `
                                                            -NodePath $nodePath `
                                                            -Version $version `
                                                            -Global `
                                                            -InCleanMode:$InCleanMode `
                                                            -ErrorAction Stop
                    $TaskParameter[$ToolInfo.PathParameterName] = $moduleRoot
                }
                default
                {
                    switch( $name )
                    {
                        'Node'
                        {
                            if( $InCleanMode )
                            {
                                if( (Test-Path -Path $nodepath -PathType Leaf) )
                                {
                                    $TaskParameter[$ToolInfo.PathParameterName] = $nodePath
                                }
                                return
                            }

                            $npmVersionToInstall = $null
                            $nodeVersionToInstall = $null
                            $nodeVersions = Invoke-RestMethod -Uri 'https://nodejs.org/dist/index.json' | ForEach-Object { $_ }
                            if( $version )
                            {
                                $nodeVersionToInstall = $nodeVersions | Where-Object { $_.version -like 'v{0}' -f $version } | Select-Object -First 1
                                if( -not $nodeVersionToInstall )
                                {
                                    throw ('Node v{0} does not exist.' -f $version)
                                }
                            }
                            else
                            {
                                $packageJsonPath = Join-Path -Path (Get-Location).ProviderPath -ChildPath 'package.json'
                                if( -not (Test-Path -Path $packageJsonPath -PathType Leaf) )
                                {
                                    $packageJsonPath = Join-Path -Path $InstallRoot -ChildPath 'package.json'
                                }

                                if( (Test-Path -Path $packageJsonPath -PathType Leaf) )
                                {
                                    Write-Verbose -Message ('Reading ''{0}'' to determine Node and NPM versions to use.' -f $packageJsonPath)
                                    $packageJson = Get-Content -Raw -Path $packageJsonPath | ConvertFrom-Json
                                    if( $packageJson -and ($packageJson | Get-Member 'engines') )
                                    {
                                        if( ($packageJson.engines | Get-Member 'node') -and $packageJson.engines.node -match '(\d+\.\d+\.\d+)' )
                                        {
                                            $nodeVersionToInstall = 'v{0}' -f $Matches[1]
                                            $nodeVersionToInstall =  $nodeVersions |
                                                            Where-Object { $_.version -eq $nodeVersionToInstall } |
                                                            Select-Object -First 1
                                        }

                                        if( ($packageJson.engines | Get-Member 'npm') -and $packageJson.engines.npm -match '(\d+\.\d+\.\d+)' )
                                        {
                                            $npmVersionToInstall = $Matches[1]
                                        }
                                    }
                                }
                            }

                            if( -not $nodeVersionToInstall )
                            {
                                $nodeVersionToInstall = $nodeVersions |
                                                           Where-Object { ($_ | Get-Member 'lts') -and $_.lts } |
                                                            Select-Object -First 1
                            }

                            if( -not $npmVersionToInstall )
                            {
                                $npmVersionToInstall = $nodeVersionToInstall.npm
                            }

                            if( (Test-Path -Path $nodePath -PathType Leaf) )
                            {
                                $currentNodeVersion = & $nodePath '--version'
                                if( $currentNodeVersion -ne $nodeVersionToInstall.version )
                                {
                                    Uninstall-WhiskeyTool -Name 'Node' -InstallRoot $InstallRoot
                                }
                            }

                            if( -not (Test-Path -Path $nodeRoot -PathType Container) )
                            {
                                New-Item -Path $nodeRoot -ItemType 'Directory' -Force | Out-Null
                            }

                            $extractedDirName = 'node-{0}-win-x64' -f $nodeVersionToInstall.version
                            $filename = '{0}.zip' -f $extractedDirName
                            $nodeZipFile = Join-Path -Path $nodeRoot -ChildPath $filename
                            if( -not (Test-Path -Path $nodeZipFile -PathType Leaf) )
                            {
                                $uri = 'https://nodejs.org/dist/{0}/{1}' -f $nodeVersionToInstall.version,$filename
                                try
                                {
                                    Invoke-WebRequest -Uri $uri -OutFile $nodeZipFile
                                }
                                catch
                                {
                                    $responseStatus = $_.Exception.Response.StatusCode
                                    $errorMsg = 'Failed to download Node {0}. Received a {1} ({2}) response when retreiving URI {3}.' -f $nodeVersionToInstall.version,$responseStatus,[int]$responseStatus,$uri
                                    if( $responseStatus -eq [Net.HttpStatusCode]::NotFound )
                                    {
                                        $errorMsg = '{0} It looks like this version of Node wasn''t packaged as a ZIP file. Please use Node v4.5.0 or newer.' -f $errorMsg
                                    }
                                    throw $errorMsg
                                }
                            }

                            if( -not (Test-Path -Path $nodePath -PathType Leaf) )
                            {
                                Write-Verbose -Message ('{0} x {1} -o{2} -y' -f $7z,$nodeZipFile,$nodeRoot)
                                & $7z 'x' $nodeZipFile ('-o{0}' -f $nodeRoot) '-y'

                                Get-ChildItem -Path $nodeRoot -Filter 'node-*' -Directory |
                                    Get-ChildItem |
                                    Move-Item -Destination $nodeRoot
                            }

                            $npmPath = Join-Path -Path $nodeRoot -ChildPath 'node_modules\npm\bin\npm-cli.js'
                            $npmVersion = & $nodePath $npmPath '--version'
                            if( $npmVersion -ne $npmVersionToInstall )
                            {
                                Write-Verbose ('Installing npm@{0}.' -f $npmVersionToInstall)
                                # Bug in NPM 5 that won't delete these files in the node home directory.
                                Get-ChildItem -Path (Join-Path -Path $nodeRoot -ChildPath '*') -Include 'npm.cmd','npm','npx.cmd','npx' | Remove-Item
                                & $nodePath $npmPath 'install' ('npm@{0}' -f $npmVersionToInstall) '-g'
                                if( $LASTEXITCODE )
                                {
                                    throw ('Failed to update to NPM {0}. Please see previous output for details.' -f $npmVersionToInstall)
                                }
                            }

                            $TaskParameter[$ToolInfo.PathParameterName] = $nodePath
                        }
                        'DotNet'
                        {
                            $TaskParameter[$ToolInfo.PathParameterName] = Install-WhiskeyDotNetTool -InstallRoot $InstallRoot -WorkingDirectory (Get-Location).ProviderPath -Version $version -ErrorAction Stop
                        }
                        default
                        {
                            throw ('Unknown tool ''{0}''. The only supported tools are ''Node'' and ''DotNet''.' -f $name)
                        }
                    }
                }
            }
        }
    }
    finally
    {
        $DebugPreference = 'Continue'
        $usedFor = (Get-Date) - $startedUsingAt
        Write-Debug -Message ('[{0:yyyy-MM-dd HH:mm:ss}]  Process "{1}" releasing mutex "{2}" after using it for {3}.' -f (Get-Date),$PID,$mutexName,$usedFor)
        $startedReleasingAt = Get-Date
        $installLock.ReleaseMutex();
        $installLock.Dispose()
        $installLock.Close()
        $installLock = $null
        $releasedDuration = (Get-Date) - $startedReleasingAt
        Write-Debug -Message ('[{0:yyyy-MM-dd HH:mm:ss}]  Process "{1}" released mutex "{2}" in {3}.' -f (Get-Date),$PID,$mutexName,$releasedDuration)
        $DebugPreference = 'SilentlyContinue'
    }
}
