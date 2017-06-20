[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]
    # The Github authentication token to use.
    $GitHubAuthToken,

    [Parameter(Mandatory=$true)]
    [string]
    # Your Github username.
    $GitHubUsername,

    [Parameter(Mandatory=$true)]
    [string]
    $BitbucketExportJsonPath,

    [int]
    $Count = 1
)

#Requires -Version 4
Set-StrictMode -Version 'Latest'

$credential = '{0}:{1}' -f $GitHubUsername,$GitHubAuthToken

$authHeaderValue = 'Basic {0}' -f [Convert]::ToBase64String( [Text.Encoding]::UTF8.GetBytes($credential) )
$headers = @{ 
                'Authorization' = $authHeaderValue;
                'Accept' = 'application/vnd.github.v3+json';
            }

$issuesUri = 'https://api.github.com/repos/pshdo/Carbon/issues'
$githubIssues = Invoke-RestMethod -Method Get -UseBasicParsing -Uri $issuesUri -Headers $headers

$issueData = Get-Content -Path $BitbucketExportJsonPath -Raw | ConvertFrom-Json 

$issueData.issues |
    Where-Object { $_.status -eq 'open' -or $_.status -eq 'new' } |
    Select-Object -First $Count |
    ForEach-Object {
        $bbIssue = $_
        #Write-Host $bbIssue.id
        $issueTag = 'bb-issue-{0}' -f $bbIssue.id
        $githubIssue = $githubIssues | Where-Object { ($_.body -match '\b{0}\b' -f [regex]::Escape($issueTag)) }
        if( -not $githubIssue )
        {
            $bbIssueUri = 'https://bitbucket.org/splatteredbits/carbon/issues/{0}' -f $bbIssue.id
            $author = ''
            $authorMention = ''
            $createdOn = [datetime]$bbIssue.created_on
            $issueImportTitle = 'Imported from [Bitbucket issue #{0}]({1})' -f $bbIssue.id,$bbIssueUri
            if( $bbIssue.reporter -ne $GitHubUsername )
            {
                $author = ' by [{0}](https://bitbucket.org/{0})' -f $bbIssue.reporter
                $authorMention = " / @$($bbIssue.reporter)"
            }
            $body = @"
#### $($issueImportTitle), created$($author) on $($created_on.ToString('yyyy-MM-dd'))
-----
$($bbIssue.content)

###### [$($issueTag)]($bbIssueUri)$($authorMention)
"@
            $githubIssueJson = [pscustomobject]@{
                                                    title = $_.title;
                                                    body = $body;
                                                    labels = @( $_.priority, $_.kind, 'from-bitbucket' );
                                                } | ConvertTo-Json -Depth 100
            $githubIssue = Invoke-RestMethod -Method Post -Uri $issuesUri -Headers $headers -Body $githubIssueJson -UseBasicParsing
        }

        $githubComments = Invoke-RestMethod -Method Get -Uri $githubIssue.comments_url -Headers $headers

        $issueData.comments |
            Where-Object { $_.issue -eq $bbIssue.id -and $_.content } |
            Sort-Object -Property { [int]$_.id } |
            ForEach-Object {
                $comment = $_

                $commentTag = 'bb-issue-comment-{0}' -f $comment.id
                $gitHubComment = $githubComments | Where-Object { $_.body -match ('\b{0}\b' -f [regex]::Escape($commentTag)) }

                $author = ''
                $authorMention = ''
                $created_on = [datetime]$comment.created_on
                if( $comment.user -ne $GitHubUsername )
                {
                    $author = ' by [{0}](https://bitbucket.org/{0})' -f $comment.user
                    $authorMention = ' / @{0}' -f $comment.user
                }
                if( -not $githubComment )
                {
                    $commentBody = @"
#### Originally created$($author) on $($created_on.ToString('yyyy-MM-dd'))

$($comment.content)

###### $($commentTag)$($authorMention)
"@
                    $commentJson = [pscustomobject]@{
                                                        body = $commentBody
                                                    } | ConvertTo-Json
                    Invoke-RestMethod -Method Post -Uri $githubIssue.comments_url -Headers $headers -Body $commentJson -UseBasicParsing
                }
            }
    }
