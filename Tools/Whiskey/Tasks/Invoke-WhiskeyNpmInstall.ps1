
function Invoke-WhiskeyNpmInstall
{
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

    Write-Warning -Message ('The "NpmInstall" task is obsolete. It will be removed in a future version of Whiskey. Please use the "Npm" task instead.')

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
