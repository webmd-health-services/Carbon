
function Install-WhiskeyNodeJs
{
    <#
    .SYNOPSIS
    Installs a specific version of Node.js and returns its path.

    .DESCRIPTION
    The `Install-WhiskeyNodeJs` function installs a specific version of Node.js and returns the path to its `node.exe` program. It uses NVM to to the installation. If NVM isn't installed/available, it will download it and install it to `%APPDATA%\nvm`.

    If the requested version of Node.js is installed, nothing happens, but the path to that version's `node.exe` is still returned.

    After installation, both Node *and* NPM will be installed together in the same directory.

    IF NVM is downloaded, the `NVM_HOME` environment variable for the current user is created to point to where NVM is installed.

    .EXAMPLE
    Install-WhiskeyNodeJs -Version '4.4.7'

    Installs version `4.4.7` of Node.js and returns the path to its `node.exe` file.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [uri]
        # The URI to the registry from which NPM packages should be downloaded.
        $RegistryUri,

        [Parameter(Mandatory=$true)]
        [string]
        # The root directory of the target Node.js application. This directory will contain the application's `package.json` config file.
        $ApplicationRoot,

        [string]
        # The directory where NVM should be installed to. Only used if NVM isn't already installed. NVM is installed to `$NvmInstallDirectory\nvm`.
        $NvmInstallDirectory,

        [Switch]
        # Install Node on a developer computer.
        $ForDeveloper
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $NvmInstallDirectory )
    {
        $NvmInstallDirectory = $env:APPDATA
    }

    if( (Test-Path -Path 'env:NVM_HOME') )
    {
        $nvmRoot = (Get-Item -Path 'env:NVM_HOME').Value
    }
    else
    {
        # On developer computers, NVM should be installed by default. If not, make the dev install it.
        if( $ForDeveloper )
        {
            Write-Error -Message (@"
NVM for Windows is not installed. To install it:

1. Uninstall any existing versions of Node.js using the "Programs and Features" Control Panel.
2. Reboot
3. Delete these folders, if they still exist:
   * C:\Program Files (x86)\Nodejs
   * C:\Program Files\Nodejs
   * C:\Users\$($env:USERNAME)\AppData\Roaming\npm (i.e. ``%APPDATA%\Roaming\npm``)
   * C:\Users\$($env:USERNAME)\AppData\Roaming\npm-cache (i.e. ``%APPDATA%\Roaming\npm-cache``)
   * C:\Users\$($env:USERNAME)\.npmrc
   * C:\Users\$($env:USERNAME)\npmrc
4. Remove any nodejs or npm paths from your %PATH% environment variable.
5. Download the latest version of NVM for Windows from Github: https://github.com/coreybutler/nvm-windows/releases
6. Right-click the .zip file, choose Properties, and click the "Unblock" button.
7. Unzip the installer
8. Run nvm-setup.exe. Leave all installation options to their defaults.
6. Restart PowerShell
"@)
            return
        }

        $nvmRoot = Join-Path -Path $NvmInstallDirectory -ChildPath 'nvm'
        Set-Item -Path 'env:NVM_HOME' -Value $nvmRoot
    }

    $nvmPath = Join-Path -Path $nvmRoot -ChildPath 'nvm.exe'

    if( -not (Test-Path -Path $nvmPath -PathType Leaf) )
    {
        $tempZipFile = 'Whiskey+Install-WhiskeyNodeJs+nvm-setup.zip+{0}' -f [IO.Path]::GetRandomFileName()
        $tempZipFile = Join-Path -Path $env:TEMP -ChildPath $tempZipFile

        $nvmUri = 'https://github.com/coreybutler/nvm-windows/releases/download/1.1.1/nvm-noinstall.zip'
        Invoke-WebRequest -Uri $nvmUri -OutFile $tempZipFile
        if( -not (Test-Path -Path $tempZipFile -PathType Leaf) )
        {
            Write-Error -Message ('Failed to download NVM from {0}' -f $nvmUri)
            return
        }

        $nvmSymlink = Join-Path -Path $env:ProgramFiles -ChildPath 'nodejs'

        Add-Type -AssemblyName 'System.IO.Compression.FileSystem'
        [IO.Compression.ZipFile]::ExtractToDirectory($tempZipFile,$nvmRoot)

        @"
root: $($nvmRoot)
path: $($nvmSymlink)
"@ | Set-Content -Path (Join-Path -Path $nvmRoot -ChildPath 'settings.txt')
    }

    if( -not (Test-Path -Path $nvmPath -PathType Leaf) )
    {
        Write-Error -Message ('Failed to install NVM to {0}.' -f $nvmRoot)
        return
    }
    
    $packageJsonPath = Resolve-Path -Path (Join-Path -Path $ApplicationRoot -ChildPath 'package.json') | Select-Object -ExpandProperty 'ProviderPath'
    if( -not $packageJsonPath )
    {
        Write-Error -Message ('Package.json file ''{0}'' does not exist. This file is mandatory when using the Node build task.' -f (Join-Path -Path (Get-Location).ProviderPath -ChildPath 'package.json'))
        return
    }

    $packageJson = Get-Content -Raw -Path $packageJsonPath | ConvertFrom-Json
    if( -not $packageJson )
    {
        Write-Error -Message ('Package.json file ''{0}'' contains invalid JSON. Please see previous errors for more information.' -f $packageJsonPath)
        return
    }

    if( -not ($packageJson | Get-Member -Name 'name') -or -not $packageJson.name )
    {
        Write-Error -Message ('Package name is missing or doesn''t have a value. Please ensure ''{0}'' contains a ''name'' field., e.g. `"name": "fubarsnafu"`. A package name is required by NSP, the Node Security Platform, when scanning for security vulnerabilities.' -f $packageJsonPath)
        return
    }

    if( -not ($packageJson | Get-Member -Name 'engines') -or -not ($packageJson.engines | Get-Member -Name 'node') )
    {
        Write-Error -Message ('Node version is not defined or is missing from the package.json file ''{0}''. Please ensure the Node version to use is defined using the package.json''s engines field, e.g. `"engines": {{ node: "VERSION" }}`. See https://docs.npmjs.com/files/package.json#engines for more information.' -f $packageJsonPath)
        return
    }

    if( $packageJson.engines.node -notmatch '(\d+\.\d+\.\d+)' )
    {
        Write-Error -Message ('Node version ''{0}'' is invalid. The Node version must be a valid semantic version. Package.json file ''{1}'', engines field:{2}{3}' -f $packageJson.engines.node,$packageJsonPath,[Environment]::NewLine,($packageJson.engines | ConvertTo-Json -Depth 50))
        return
    }

    $version = $Matches[1]

    $activity = 'Installing Node.js {0}' -f $version
    Write-Progress -Activity $activity
    $output = & $nvmPath install $version 64 | 
                Where-Object { $_ } |
                ForEach-Object { Write-Progress -Activity $activity -Status $_; $_ }
    Write-Progress -Activity $activity -Completed

    $versionRoot = Join-Path -Path $nvmRoot -ChildPath ('v{0}' -f $version)
    $node64Path = Join-Path -Path $versionRoot -ChildPath 'node64.exe'
    $nodePath = Join-Path -Path $versionRoot -ChildPath 'node.exe'
    if( (Test-Path -Path $node64Path -PathType Leaf) )
    {
        Move-Item -Path $node64Path -Destination $nodePath -Force
    }

    if( (Test-Path -Path $nodePath -PathType Leaf) )
    {
        $npmPath = Join-Path -Path $versionRoot -ChildPath 'node_modules\npm\bin\npm-cli.js' -Resolve
        [version]$version = & $nodePath $npmPath '--version'
        if( $version -lt [version]'3.0' )
        {
            $activity = 'Upgrading NPM to version 3.'
            & $nodePath $npmPath 'install' 'npm@3' '-g' | 
                Where-Object { $_ } |
                ForEach-Object { Write-Progress -Activity $activity -Status $_ ; }
            Write-Progress -Activity $activity -Completed
        }

        $npmRegistry = & $nodePath $npmPath config --global get registry
        if( $npmRegistry -ne $RegistryUri.ToString() )
        {
            Write-Verbose ('NPM  registry  {0} -> {1}' -f $npmRegistry,$RegistryUri)
            Invoke-Command -ScriptBlock { & $nodePath $npmPath config --global set registry $RegistryUri }
        }

        $myAlwaysAuth = 'false'
        $alwaysAuth = & $nodePath $npmPath config --global get 'always-auth'
        if( $alwaysAuth -ne $myAlwaysAuth )
        {
            Write-Verbose -Message ('NPM  config  always-auth  {0} -> {1}' -f $alwaysAuth,$myAlwaysAuth)
            & $nodePath $npmPath config --global set 'always-auth' $myAlwaysAuth
        }

        return $nodePath
    }

    Write-Error -Message ('Failed to install Node.js version {0}.{1}{2}' -f $version,[Environment]::NewLine,($output -join [Environment]::NewLine))
}
