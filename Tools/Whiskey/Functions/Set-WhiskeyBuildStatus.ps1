
function Set-WhiskeyBuildStatus
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        $Context,

        [Parameter(Mandatory=$true)]
        [ValidateSet('Started','Completed','Failed')]
        # The build status. Should be one of `Started`, `Completed`, or `Failed`.
        $Status
    )

    Set-StrictMode -Version 'Latest'

    if( $Context.ByDeveloper )
    {
        return
    }

    $reportingTo = $Context.Configuration['PublishBuildStatusTo']

    if( -not $reportingTo )
    {
        return
    }

    $reporterIdx = -1
    foreach( $reporter in $reportingTo )
    {
        $reporterIdx++
        $reporterName = $reporter.Keys | Select-Object -First 1
        $propertyDescription = 'PublishBuildStatusTo[{0}]: {1}' -f $reporterIdx,$reporterName
        $reporterConfig = $reporter[$reporterName]
        switch( $reporterName )
        {
            'BitbucketServer'
            {
                $uri = $reporterConfig['Uri']
                if( -not $uri )
                {
                    Stop-WhiskeyTask -TaskContext $Context -PropertyDescription $propertyDescription -Message (@'
Property 'Uri' does not exist or does not have a value. Set this property to the Bitbucket Server URI where you want build statuses reported to, e.g.,
 
    PublishBuildStatusTo:
    - BitbucketServer:
        Uri: BITBUCKET_SERVER_URI
        CredentialID: CREDENTIAL_ID
        
'@ -f $uri)
                }
                $credID = $reporterConfig['CredentialID']
                if( -not $credID )
                {
                    Stop-WhiskeyTask -TaskContext $Context -PropertyDescription $propertyDescription -Message (@'
Property 'CredentialID' does not exist or does not have a value. Set this property to the ID of the credential to use when connecting to the Bitbucket Server at '{0}', e.g.,
 
    PublishBuildStatusTo:
    - BitbucketServer:
        Uri: {0}
        CredentialID: CREDENTIAL_ID
 
Use the `Add-WhiskeyCredential` function to add the credential to the build.`
'@ -f $uri)
                }
                $credential = Get-WhiskeyCredential -Context $Context -ID $credID -PropertyName 'CredentialID' -PropertyDescription $propertyDescription
                $conn = New-BBServerConnection -Credential $credential -Uri $uri
                $statusMap = @{
                                    'Started' = 'INPROGRESS';
                                    'Completed' = 'Successful';
                                    'Failed' = 'Failed'
                              }

                $buildInfo = $Context.BuildMetadata
                Set-BBServerCommitBuildStatus -Connection $conn -Status $statusMap[$Status] -CommitID $buildInfo.ScmCommitID -Key $buildInfo.JobUri -BuildUri $buildInfo.BuildUri -Name $buildInfo.JobName
            }

            default
            {
                Stop-WhiskeyTask -TaskContext $Context -PropertyDescription $propertyDescription -Message ('Unknown build status reporter ''{0}''. Supported reporters are ''BitbucketServer''.' -f $reporterName)
            }
        }
    }
}

