
function Set-CIisWebsiteID
{
    <#
    .SYNOPSIS
    Sets a website's ID to an explicit number.

    .DESCRIPTION
    IIS handles assigning websites individual IDs.  This method will assign a website explicit ID you manage (e.g. to support session sharing in a web server farm).

    If another site already exists with that ID, you'll get an error.

    When you change a website's ID, IIS will stop the site, but not start the site after saving the ID change. This function waits until the site's ID is changed, and then will start the website.

    Beginning with Carbon 2.0.1, this function is available only if IIS is installed.

    .EXAMPLE
    Set-CIisWebsiteID -SiteName Holodeck -ID 483

    Sets the `Holodeck` website's ID to `483`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The website name.
        $SiteName,

        [Parameter(Mandatory=$true)]
        [int]
        # The website's new ID.
        $ID
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if( -not (Test-CIisWebsite -Name $SiteName) )
    {
        Write-Error ('Website {0} not found.' -f $SiteName)
        return
    }

    $websiteWithID = Get-CIisWebsite | Where-Object { $_.ID -eq $ID -and $_.Name -ne $SiteName }
    if( $websiteWithID )
    {
        Write-Error -Message ('ID {0} already in use for website {1}.' -f $ID,$SiteName) -Category ResourceExists
        return
    }

    $website = Get-CIisWebsite -SiteName $SiteName
    $startWhenDone = $false
    if( $website.ID -ne $ID )
    {
        if( $PSCmdlet.ShouldProcess( ('website {0}' -f $SiteName), ('set site ID to {0}' -f $ID) ) )
        {
            $startWhenDone = ($website.State -eq 'Started')
            $website.ID = $ID
            $website.CommitChanges()
        }
    }

    if( $PSBoundParameters.ContainsKey('WhatIf') )
    {
        return
    }

    # Make sure the website's ID gets updated
    $website = $null
    $maxTries = 100
    $numTries = 0
    do
    {
        Start-Sleep -Milliseconds 100
        $website = Get-CIisWebsite -SiteName $SiteName
        if( $website -and $website.ID -eq $ID )
        {
            break
        }
        $numTries++
    }
    while( $numTries -lt $maxTries )

    if( -not $website -or $website.ID -ne $ID )
    {
        Write-Error ('IIS:/{0}: site ID hasn''t changed to {1} after waiting 10 seconds. Please check IIS configuration.' -f $SiteName,$ID)
    }

    if( -not $startWhenDone )
    {
        return
    }

    # Now, start the website.
    $numTries = 0
    do
    {
        # Sometimes, the website is invalid and Start() throws an exception.
        try
        {
            if( $website )
            {
                $null = $website.Start()
            }
        }
        catch
        {
            $website = $null
        }

        Start-Sleep -Milliseconds 100
        $website = Get-CIisWebsite -SiteName $SiteName
        if( $website -and $website.State -eq 'Started' )
        {
            break
        }
        $numTries++
    }
    while( $numTries -lt $maxTries )

    if( -not $website -or $website.State -ne 'Started' )
    {
        Write-Error ('IIS:/{0}: failed to start website after setting ID to {1}' -f $SiteName,$ID)
    }
}

