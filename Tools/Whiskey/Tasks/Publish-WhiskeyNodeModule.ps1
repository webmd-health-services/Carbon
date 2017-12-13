
function Publish-WhiskeyNodeModule
{
    <#
    .SYNOPSIS
    Publishes a Node module package to the target NPM registry
    
    .DESCRIPTION
    The `Publish-WhiskeyNodeModule` function utilizes NPM's `publish` command to publish Node module packages.

    You are required to specify what version of Node.js you want in the engines field of your package.json file. (See https://docs.npmjs.com/files/package.json#engines for more information.) The version of Node is installed for you using NVM. 

    This task accepts these parameters:

    * `WorkingDirectory`: the directory where the NPM publish command will be run. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.
    
    .EXAMPLE
    Publish-WhiskeyNodeModule -TaskContext $context -TaskParameter @{}

    Demonstrates how to `publish` the Node module package located in the directory specified by the `$context.BuildRoot` property. The function would run `npm publish`.

    Publish-WhiskeyNodeModule -TaskContext $context -TaskParameter @{ WorkingDirectory = '\PathToPackage\RelativeTo\whiskey.yml' }

    Demonstrates how to `publish` the Node module package located in the directory specified by the `WorkingDirectory` property. The function would run `npm publish`.
    #>
    [Whiskey.Task("PublishNodeModule", SupportsInitialize=$true)]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context the task is running under.
        $TaskContext,

        [Parameter(Mandatory=$true)]
        [hashtable]
        # The parameters/configuration to use to run the task. Should be a hashtable that contains the following item:
        #
        # * `WorkingDirectory` (Optional): Provides the default root directory for the NPM `publish` task. Defaults to the directory where the build's `whiskey.yml` file was found. Must be relative to the `whiskey.yml` file.                     
        $TaskParameter
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    $workingDir = $TaskContext.BuildRoot
    if($TaskParameter.ContainsKey('WorkingDirectory'))
    {
        $workingDir = $TaskParameter['WorkingDirectory'] | Resolve-WhiskeyTaskPath -TaskContext $TaskContext -PropertyName 'WorkingDirectory'
    }

    $npmRegistryUri = [uri]$TaskParameter['NpmRegistryUri']
    if (-not $npmRegistryUri) 
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''NpmRegistryUri'' is mandatory and must be a URI. It should be the URI to the registry where the module should be published. E.g.,
        
    BuildTasks:
    - PublishNodeModule:
        NpmRegistryUri: https://registry.npmjs.org/
    '
    }
    $nodePath = Install-WhiskeyNodeJs -RegistryUri $npmRegistryUri -ApplicationRoot $workingDir -ForDeveloper:$TaskContext.ByDeveloper
    
    if( $TaskContext.ShouldInitialize() )
    {
        return
    }

    if (!$TaskContext.Publish)
    {
        return
    }
    
    $npmConfigPrefix = '//{0}{1}:' -f $npmregistryUri.Authority,$npmRegistryUri.LocalPath

    $credentialID = $TaskParameter['CredentialID']
    if( -not $credentialID )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''CredentialID'' is mandatory. It should be the ID of the credential to use when publishing to ''{0}'', e.g.
    
    BuildTasks:
    - PublishNodeModule:
        NpmRegistryUri: {0}
        CredentialID: NpmCredential
    
    Use the `Add-WhiskeyCredential` function to add the credential to the build.
    ' -f $npmRegistryUri)
    }
    $credential = Get-WhiskeyCredential -Context $TaskContext -ID $credentialID -PropertyName 'CredentialID'
    $npmUserName = $credential.UserName
    $npmEmail = $TaskParameter['EmailAddress']
    if( -not $npmEmail )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message ('Property ''EmailAddress'' is mandatory. It should be the e-mail address of the user publishing the module, e.g.
    
    BuildTasks:
    - PublishNodeModule:
        NpmRegistryUri: {0}
        CredentialID: {1}
        EmailAddress: somebody@example.com
    ' -f $npmRegistryUri,$credentialID)
    }
    $npmCredPassword = $credential.GetNetworkCredential().Password
    $npmBytesPassword  = [System.Text.Encoding]::UTF8.GetBytes($npmCredPassword)
    $npmPassword = [System.Convert]::ToBase64String($npmBytesPassword)

    Push-Location $workingDir
    try
    {
        $packageNpmrc = New-Item -Path '.npmrc' -ItemType File -Force
        Add-Content -Path $packageNpmrc -Value ('{0}_password="{1}"' -f $npmConfigPrefix, $npmPassword)
        Add-Content -Path $packageNpmrc -Value ('{0}username={1}' -f $npmConfigPrefix, $npmUserName)
        Add-Content -Path $packageNpmrc -Value ('{0}email={1}' -f $npmConfigPrefix, $npmEmail)
        Write-Verbose -Message ('Creating .npmrc at {0}.' -f $packageNpmrc)
        Get-Content -Path $packageNpmrc |
            ForEach-Object {
                if( $_ -match '_password' )
                {
                    return $_ -replace '=(.*)$','=********'
                }
                return $_
            } |
            Write-Verbose

        $npmPath = Get-WhiskeyNPMPath -NodePath $nodePath -ApplicationRoot $workingDir
        Write-Verbose -Message 'Removing extraneous packages with ''npm prune'''
        Invoke-Command -ScriptBlock {
            & $nodePath $npmPath prune --production --no-color
        }
        
        if ($LASTEXITCODE -ne 0)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NPM command ''npm prune'' failed with exit code ''{0}''.' -f $LASTEXITCODE)
        }
        
        # local version of npm gets removed by 'npm prune', so call Get-WhiskeyNPMPath to download it again so we can also use the desired version of npm for publishing
        $npmPath = Get-WhiskeyNPMPath -NodePath $nodePath -ApplicationRoot $workingDir
        Write-Verbose -Message 'Publishing package with ''npm publish'''
        Invoke-Command -ScriptBlock {
            & $nodePath $npmPath publish
        }
        
        if ($LASTEXITCODE -ne 0)
        {
            Stop-WhiskeyTask -TaskContext $TaskContext -Message ('NPM command ''npm publish'' failed with exit code ''{0}''.' -f $LASTEXITCODE)
        }
    }
    finally
    {
        if (Test-Path $packageNpmrc)
        {
            Write-Verbose -Message ('Removing .npmrc at {0}.' -f $packageNpmrc)
            Remove-Item -Path $packageNpmrc
        }
        
        Pop-Location
    }
}
