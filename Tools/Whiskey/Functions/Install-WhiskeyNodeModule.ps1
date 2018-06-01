
function Install-WhiskeyNodeModule
{
    <#
    .SYNOPSIS
    Installs Node.js modules
    
    .DESCRIPTION
    The `Install-WhiskeyNodeModule` function installs Node.js modules to the `node_modules` directory located in the current working directory. The path to the module's directory is returned.

    Failing to install a module does not cause a bulid to fail. If you want a build to fail if the module fails to install, you must pass `-ErrorAction Stop`.
    
    .EXAMPLE
    Install-WhiskeyNodeModule -Name 'rimraf' -Version '^2.0.0' -NodePath $TaskParameter['NodePath']

    This example will install the Node module `rimraf` at the latest `2.x.x` version in the `node_modules` directory located in the current directory.
    
    .EXAMPLE
    Install-WhiskeyNodeModule -Name 'rimraf' -Version '^2.0.0' -NodePath $TaskParameter['NodePath -ErrorAction Stop

    Demonstrates how to fail a build if installing the module fails by setting the `ErrorAction` parameter to `Stop`.
    #>
    
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the module to install.
        $Name,

        [string]
        # The version of the module to install.
        $Version,

        [switch]
        # Node modules are being installed on a developer computer.
        $ForDeveloper,

        [Parameter(Mandatory=$true)]
        [string]
        # The path to the node executable.
        $NodePath,

        [Switch]
        # Whether or not to install the module globally.
        $Global,

        [Switch]
        # Are we running in clean mode?
        $InCleanMode
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $npmArgument = & {
                        if( $Version )
                        {
                            ('{0}@{1}' -f $Name,$Version)
                        }
                        else
                        {
                            $Name
                        }
                        if( $Global )
                        {
                            '-g'
                        }
                    }

    $nodeRoot = (Get-Location).ProviderPath
    if( $Global )
    {
        $nodeRoot = $NodePath | Split-Path
    }

    $modulePath = Join-Path -Path $nodeRoot -ChildPath ('node_modules\{0}' -f $Name)
    if( (Test-Path -Path $modulePath -PathType Container) )
    {
        return $modulePath
    }
    elseif( $InCleanMode )
    {
        return
    }

    Invoke-WhiskeyNpmCommand -Name 'install' -ArgumentList $npmArgument -NodePath $NodePath -ForDeveloper:$ForDeveloper | Write-Verbose
    if( $LASTEXITCODE )
    {
        return
    }

    if( -not (Test-Path -Path $modulePath -PathType Container))
    {
        Write-Error -Message ('NPM executed successfully when attempting to install ''{0}'' but the module was not found at ''{1}''' -f ($npmArgument -join ' '),$modulePath)
        return
    }

    return $modulePath
}
