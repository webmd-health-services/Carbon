$authToken = '52c4cd9eae04878f7fa0ae216e4b92a71345979a'

$credential = 'splatteredbits:{1}' -f $credential.UserName,$authToken

    $authHeaderValue = 'Basic {0}' -f [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes($credential) )
    $headers = @{ 'Authorization' = $authHeaderValue }
    $authHeader = 

$issueData = Get-Content C:\Users\Aaron\Documents\CarbonBitbucketIssues.json -Raw |
                ConvertFrom-Json 

$issueData.issues |
    Where-Object { $_.status -eq 'open' -or $_.status -eq 'new' } |
    ForEach-Object {
        $issue = $_
        #Write-Host $issue.id
        $body = $_.content
        if( $_.user -ne 'splatteredbits' )
        {
            $body = ("{0}{1}{1}Originally submitted by [{2}](https://bitbucket.org/{2}) as [Bitbucket issue #{3}](https://bitbucket.org/splatteredbits/carbon/issues/{3}/)" -f $_.content,[Environment]::NewLine,$issue.reporter,$issue.id)
        }
        [pscustomobject]@{
                            title = $_.title;
                            body = $body;
                            labels = @( $_.priority, $_.kind );
                         } | ConvertTo-Json -Depth 100 #| Out-Null
        $issueData.comments |
            Where-Object { $_.issue -eq $issue.id -and $_.content } |
            foreach {
                $commentBody = $_.content
                if( $_.user -ne 'splatteredbits' )
                {
                    $commentBody = ('{0}{1}{1}Originally made by [{2}](https://bitbucket.org/{2}).' -f $_.content,[Environment]::NewLine,$_.user)
                }

                [pscustomobject]@{
                                    body = $commentBody
                                 } | ConvertTo-Json
            }
    }
