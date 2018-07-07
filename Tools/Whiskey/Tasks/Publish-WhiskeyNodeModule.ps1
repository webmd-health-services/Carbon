
function Publish-WhiskeyNodeModule
{
    [Whiskey.Task("PublishNodeModule")]
    [Whiskey.RequiresTool("Node", "NodePath",VersionParameterName='NodeVersion')]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Whiskey.Context]
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

    $workingDirectory = (Get-Location).ProviderPath

    $npmRegistryUri = [uri]$TaskParameter['NpmRegistryUri']
    if (-not $npmRegistryUri) 
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message 'Property ''NpmRegistryUri'' is mandatory and must be a URI. It should be the URI to the registry where the module should be published. E.g.,
        
    Build:
    - PublishNodeModule:
        NpmRegistryUri: https://registry.npmjs.org/
    '
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
    
    Build:
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
    
    Build:
    - PublishNodeModule:
        NpmRegistryUri: {0}
        CredentialID: {1}
        EmailAddress: somebody@example.com
    ' -f $npmRegistryUri,$credentialID)
    }
    $npmCredPassword = $credential.GetNetworkCredential().Password
    $npmBytesPassword  = [System.Text.Encoding]::UTF8.GetBytes($npmCredPassword)
    $npmPassword = [System.Convert]::ToBase64String($npmBytesPassword)

    try
    {
        $packageNpmrc = New-Item -Path '.npmrc' -ItemType File -Force
        Add-Content -Path $packageNpmrc -Value ('{0}_password="{1}"' -f $npmConfigPrefix, $npmPassword)
        Add-Content -Path $packageNpmrc -Value ('{0}username={1}' -f $npmConfigPrefix, $npmUserName)
        Add-Content -Path $packageNpmrc -Value ('{0}email={1}' -f $npmConfigPrefix, $npmEmail)
        Add-Content -Path $packageNpmrc -Value ('registry={0}' -f $npmRegistryUri)
        Write-WhiskeyVerbose -Context $TaskContext -Message ('Creating .npmrc at {0}.' -f $packageNpmrc)
        Get-Content -Path $packageNpmrc |
            ForEach-Object {
                if( $_ -match '_password' )
                {
                    return $_ -replace '=(.*)$','=********'
                }
                return $_
            } |
            Write-WhiskeyVerbose -Context $TaskContext

        Invoke-WhiskeyNpmCommand -Name 'prune' -ArgumentList '--production' -NodePath $TaskParameter['NodePath'] -ErrorAction Stop
        Invoke-WhiskeyNpmCommand -Name 'publish' -NodePath $TaskParameter['NodePath'] -ErrorAction Stop
    }
    finally
    {
        if (Test-Path $packageNpmrc)
        {
            Write-WhiskeyVerbose -Context $TaskContext -Message ('Removing .npmrc at {0}.' -f $packageNpmrc)
            Remove-Item -Path $packageNpmrc
        }
    }
}
