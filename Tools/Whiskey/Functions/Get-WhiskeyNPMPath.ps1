
function Get-WhiskeyNPMPath
{

    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $ApplicationRoot,

        [Parameter(Mandatory=$true)]
        [string]
        $NodePath
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $npmGlobalPath = (Join-Path -Path ($NodePath | Split-Path) -ChildPath 'node_modules\npm\bin\npm-cli.js')

    $packageJsonPath = Resolve-Path -Path (Join-Path -Path $ApplicationRoot -ChildPath 'package.json') | Select-Object -ExpandProperty 'ProviderPath'
    $packageJson = Get-Content -Raw -Path $packageJsonPath | ConvertFrom-Json

    if ( ($packageJson | Get-Member -Name 'engines') -and ($packageJson.engines | Get-Member -Name 'npm') )
    {
        if( $packageJson.engines.npm -notmatch '(\d+\.\d+\.\d+)' )
        {
            Write-Error -Message ('NPM version ''{0}'' is invalid. The NPM version must be a valid semantic version. Package.json file ''{1}'', engines field:{2}{3}' -f $packageJson.engines.npm,$packageJsonPath,[Environment]::NewLine,($packageJson.engines | ConvertTo-Json -Depth 50))
            return
        }
        $version = $Matches[1]

        $localNpmPath = (Join-Path -Path $ApplicationRoot -ChildPath 'node_modules\npm\bin\npm-cli.js')
        $localNpmMetadata = Get-Content -Path (Join-Path -Path $ApplicationRoot -ChildPath 'node_modules\npm\package.json') -ErrorAction Ignore | ConvertFrom-Json

        if ((Test-Path -Path $localNpmPath -PathType Leaf) -and ($localNpmMetadata.Version -eq $version))
        {
            return $localNpmPath
        }

        Push-Location -Path $ApplicationRoot
        Try
        {
            $version = $Matches[1]
            $npmVersion = ('npm@{0}' -f $version)

            $activity = ('Installing local NPM version {0}' -f $version)
            Invoke-Command -ScriptBlock {
                & $NodePath $npmGlobalPath 'install' $npmVersion '--no-save' |
                    Where-Object { $_ } |
                    ForEach-Object { Write-Progress -Activity $activity -Status $_ ; }
            }
            Write-Progress -Activity $activity -Completed

            if ( $LASTEXITCODE )
            {
                Write-Error -Message ('NPM failed to install NPM version ''{0}'' specified in package.json. NPM returned with exit code ''{1}''.' -f $version,$LASTEXITCODE)
                return
            }
        }
        finally
        {
            Pop-Location
        }

        return $localNpmPath
    }
    else
    {
        return $npmGlobalPath
    }
}