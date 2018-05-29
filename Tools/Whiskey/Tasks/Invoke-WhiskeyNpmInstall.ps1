
function Invoke-WhiskeyNpmInstall
{
    <#
    .SYNOPSIS
    Installs Node.js packages.

    .DESCRIPTION
    The `NpmInstall` task will use NPM's `install` command to install Node.js packages. By default, the task will run `npm install` to install all packages listed in your `package.json` file's `dependency` and `devDependency` properties. 
    
    You can install a specific package with the `Package` property. It should be a list of package names. You can specify a specific version of the module with this syntax:

        Build:
        - NpmInstall:
            Package:
            - rimraf: ^2.0.0

    In this example, the latest 2.x version of the `rimraf` module would be installed.

    This task will install the latest LTS version of Node into a `.node` directory (in the same directory as your whiskey.yml file). To use a specific version, set the `engines.node` property in your package.json file to the version you want. (See https://docs.npmjs.com/files/package.json#engines for more information.)

    You may additionally specify a version of NPM to use in the `engines.npm` field of your package.json file. The version of NPM will be upgraded to that version. Downgrading to a version older than the one that ships with your version of Node is not supported.

    # Properties

    * `Package`: a list of NPM packages to install. List items can simply be package names, `rimraf`, or package names with semantic version numbers that NPM understands, e.g. `rimraf: ^2.0.0`. When using the `Package` property the task will only install the given packages and not the ones listed in the `package.json` file.
    * `WorkingDirectory`: the directory where the `package.json` exists. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
    * `Global`: installs the module in the global `node_modules` directory, i.e. in the `.node\node_modules` directory where Whiskey installs your global copy of Node. This property is only used if the `Package` property has a value, i.e. if you are installing specific Node modules.
    * `NodeVersion`: the version of Node to use. By default, the version in the `engines.node` property of your package.json file is used. If that is missing, the latest LTS version of Node is used. By default, the version of NPM that shipped with that version of Node is used. You can customize what version of NPM to use by setting the `engines.npm` property in your package.json file to the version you want.

    # Examples

    ## Example 1

        Build:
        - NpmInstall

    This example will install all the Node packages listed in the `package.json` file to the `BUILD_ROOT\node_modules` directory.

    ## Example 2

        Build:
        - NpmInstall:
            Package:
            - gulp

    This example will install the Node package `gulp` to the `BUILD_ROOT\node_modules` directory.

    ## Example 3

        Build:
        - NpmInstall:
            WorkingDirectory: app
            Package:
            - gulp
            - rimraf: ^2.0.0

    This example will install the Node packages `gulp` and the latest 2.x.x version of `rimraf` to the `BUILD_ROOT\app\node_modules` directory.
    #>
    [Whiskey.Task('NpmInstall',SupportsClean=$true)]
    [Whiskey.RequiresTool('Node', 'NodePath',VersionParameterName='NodeVersion')]
    [CmdletBinding()]
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

    $workingDirectory = (Get-Location).ProviderPath

    if( -not $TaskParameter['Package'] )
    {
        if( $TaskContext.ShouldClean )
        {
            Write-WhiskeyTiming -Message 'Removing project node_modules'
            Remove-WhiskeyFileSystemItem -Path 'node_modules' -ErrorAction Stop
        }
        else
        {
            Write-WhiskeyTiming -Message 'Installing Node modules'
            Invoke-WhiskeyNpmCommand -Name 'install' -ArgumentList '--production=false' -NodePath $TaskParameter['NodePath'] -ForDeveloper:$TaskContext.ByDeveloper -ErrorAction Stop
        }
        Write-WhiskeyTiming -Message 'COMPLETE'
    }
    else
    {
        $installGlobally = $false
        if( $TaskParameter.ContainsKey('Global') )
        {
            $installGlobally = $TaskParameter['Global'] | ConvertFrom-WhiskeyYamlScalar
        }

        foreach( $package in $TaskParameter['Package'] )
        {
            $packageVersion = ''
            if ($package | Get-Member -Name 'Keys')
            {
                $packageName = $package.Keys | Select-Object -First 1
                $packageVersion = $package[$packageName]
            }
            else
            {
                $packageName = $package
            }

            if( $TaskContext.ShouldClean )
            {
                if( $TaskParameter.ContainsKey('NodePath') -and (Test-Path -Path $TaskParameter['NodePath'] -PathType Leaf) )
                {
                    Write-WhiskeyTiming -Message ('Uninstalling {0}' -f $packageName)
                    Uninstall-WhiskeyNodeModule -NodePath $TaskParameter['NodePath'] `
                                                -Name $packageName `
                                                -ForDeveloper:$TaskContext.ByDeveloper `
                                                -Global:$installGlobally `
                                                -ErrorAction Stop
                }
            }
            else
            {
                Write-WhiskeyTiming -Message ('Installing {0}' -f $packageName)
                Install-WhiskeyNodeModule -NodePath $TaskParameter['NodePath'] `
                                          -Name $packageName `
                                          -Version $packageVersion `
                                          -ForDeveloper:$TaskContext.ByDeveloper `
                                          -Global:$installGlobally `
                                          -ErrorAction Stop
            }
            Write-WhiskeyTiming -Message 'COMPLETE'
        }
    }
}
