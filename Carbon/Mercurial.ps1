
function Set-HgrcDefaultPushUrl
{
    <#
    .SYNOPSIS
    Updates the default-push entry in a repository's hgrc file.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the repository whose default-push URL should be updated.
        $RepoPath,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The value of the default-push URL.
        $DefaultPushUrl
    )
    
    $hgrcPath = Join-Path $RepoPath .hg\hgrc
    if( -not (Test-Path $hgrcPath -PathType Leaf) )
    {
        Write-Error "'$RepoPath' isn't a Mercurial repository; couldn't find '$hgrcPath'."
        return
    }
    
    Set-IniEntry -Path $hgrcPath -Section paths -Name 'default-push' -Value $DefaultPushUrl
}

