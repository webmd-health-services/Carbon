
function Publish-WhiskeyBBServerTag
{
    [CmdletBinding()]
    [Whiskey.Task("PublishBitbucketServerTag")]
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

    $exampleTask = 'Publish:
        - PublishBitbucketServerTag:
            CredentialID: BitbucketServerCredential
            Uri: https://bitbucketserver.example.com'

    if( -not $TaskParameter['CredentialID'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message "Property 'CredentialID' is mandatory. It should be the ID of the credential to use when connecting to Bitbucket Server:
        
        $exampleTask
        
        Use the `Add-WhiskeyCredential` function to add credentials to the build.
        "
    }
    
    if( -not $TaskParameter['Uri'] )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -Message "Property 'Uri' is mandatory. It should be the URL to the instance of Bitbucket Server where the tag should be created:
        
        $exampleTask
        "
    }
    
    $commitHash = $TaskContext.BuildMetadata.ScmCommitID
    if( -not $commitHash )
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -PropertyDescription '' -Message ('Unable to identify a valid commit to tag. Are you sure you''re running under a build server?')
    }

    if( $TaskParameter['ProjectKey'] -and $TaskParameter['RepositoryKey'] )
    {
        $projectKey = $TaskParameter['ProjectKey']
        $repoKey = $TaskParameter['RepositoryKey']
    }
    elseif( $TaskContext.BuildMetadata.ScmUri -and $TaskContext.BuildMetadata.ScmUri.Segments )
    {
        $uri = [uri]$TaskContext.BuildMetadata.ScmUri
        $projectKey = $uri.Segments[-2].Trim('/')
        $repoKey = $uri.Segments[-1] -replace '\.git$',''
    }
    else
    {
        Stop-WhiskeyTask -TaskContext $TaskContext -PropertyDescription '' -Message ("Unable to determine the repository where we should create the tag. Either create a `GIT_URL` environment variable that is the URI used to clone your repository, or add your repository''s project and repository keys as `ProjectKey` and `RepositoryKey` properties, respectively, on this task:
        
        Publish:
        - PublishBitbucketServerTag:
            CredentialID: $($TaskParameter['CredentialID'])
            Uri: $($TaskParameter['Uri'])
            ProjectKey: PROJECT_KEY
            RepositoryKey: REPOSITORY_KEY
       ") 
    }
 
    $credentialID = $TaskParameter['CredentialID']
    $credential = Get-WhiskeyCredential -Context $TaskContext -ID $credentialID -PropertyName 'CredentialID'
    $connection = New-BBServerConnection -Credential $credential -Uri $TaskParameter['Uri']
    $tag = $TaskContext.Version.SemVer2NoBuildMetadata
    Write-WhiskeyVerbose -Context $TaskContext -Message ('[{0}]  [{1}]  [{2}]  {3} -> {4}' -f $TaskParameter['Uri'],$projectKey,$repoKey,$commitHash,$tag)
    New-BBServerTag -Connection $connection -ProjectKey $projectKey -force -RepositoryKey $repoKey -Name $tag -CommitID $commitHash -ErrorAction Stop
}
