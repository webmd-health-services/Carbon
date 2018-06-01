function Publish-WhiskeyPowerShellModule
{
    [Whiskey.Task("PublishPowerShellModule")]
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
    
    if( -not $TaskParameter.ContainsKey('RepositoryName') )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''RepositoryName'' is mandatory. It should be the name of the PowerShell repository you want to publish to, e.g.
            
        Build:
        - PublishPowerShellModule:
            Path: mymodule
            RepositoryName: PSGallery
        ')
    }
    $repositoryName = $TaskParameter['RepositoryName']

    if( -not ($TaskParameter.ContainsKey('Path')))
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Element ''Path'' is mandatory. It should a path relative to your whiskey.yml file, to the module directory of the module to publish, e.g. 
        
        Build:
        - PublishPowerShellModule:
            Path: mymodule
            RepositoryName: PSGallery
        ')
    }

    $path = $TaskParameter['Path'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'Path'        
    if( -not (Test-Path $path -PathType Container) )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Path ''{0}'' isn''t a directory. It must be the path to the root directory of a Powershell module. The directory name must match the name of the module.' -f $path)
    }
                
    $publishLocation = $TaskParameter['RepositoryUri']
    if( -not $publishLocation )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''RepositoryUri'' is mandatory. It must be the URI to the PowerShall repository to publish to.')
    }

    $apiKeyID = $TaskParameter['ApiKeyID']
    if( -not $apiKeyID )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''ApiKeyID'' is mandatory. It must be the ID of the API key to use when publishing to ''{0}''. Use the `Add-WhiskeyApiKey` function to add API keys to the build.' -f $publishLocation)
    }

    $apiKey = Get-WhiskeyApiKey -Context $TaskContext -ID $apiKeyID -PropertyName 'ApiKeyID'

    $manifestPath = '{0}\{1}.psd1' -f $path,($path | Split-Path -Leaf)
    if( $TaskParameter.ContainsKey('ModuleManifestPath') )
    {
        $manifestPath = $TaskParameter.ModuleManifestPath
    }
    if( -not (Test-Path -Path $manifestPath -PathType Leaf) )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Module Manifest Path {0} is invalid, please check that the {1}.psd1 file is valid and in the correct location.' -f $manifestPath, ($path | Split-Path -Leaf))
    }

    $manifest = Get-Content $manifestPath
    $versionString = "ModuleVersion = '{0}.{1}.{2}'" -f ( $TaskContext.Version.SemVer2.Major, $TaskContext.Version.SemVer2.Minor, $TaskContext.Version.SemVer2.Patch )
    $manifest = $manifest -replace "ModuleVersion\s*=\s*('|"")[^'""]*('|"")", $versionString 
    $manifest | Set-Content $manifestPath

    $whiskeyRoot = Join-Path -Path $PSScriptRoot -ChildPath '..' -Resolve
    Start-Job -ScriptBlock {
                param(
                    $RepositoryName,
                    $PublishLocation,
                    $ApiKey,
                    $WhiskeyRoot,
                    $Path
                )

                Import-Module -Name (Join-Path -Path $whiskeyRoot -ChildPath 'Whiskey.psd1')
                Import-Module -Name (Join-Path -Path $whiskeyRoot -ChildPath 'PackageManagement' -Resolve)
                Import-Module -Name (Join-Path -Path $whiskeyRoot -ChildPath 'PowerShellGet' -Resolve)

                if( -not (Get-PSRepository -Name $repositoryName -ErrorAction Ignore) )
                {
                    Register-PSRepository -Name $repositoryName -SourceLocation $publishLocation -PublishLocation $publishLocation -InstallationPolicy Trusted -PackageManagementProvider NuGet  -Verbose
                }
  
                # Publish-Module needs nuget.exe. If it isn't in the PATH, it tries to install it, which doesn't work when running non-interactively.
                $binPath = Join-Path -Path $whiskeyRoot -ChildPath 'bin' -Resolve
                Set-Item -Path 'env:PATH' -Value ('{0};{1}' -f $binPath,$env:PATH)
                Publish-Module -Path $path -Repository $repositoryName -Verbose -NuGetApiKey $apiKey

            } -ArgumentList $repositoryName,$publishLocation,$apiKey,$whiskeyRoot,$path |
        Wait-Job | 
        Receive-Job
}
