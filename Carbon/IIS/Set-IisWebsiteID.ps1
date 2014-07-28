# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

function Set-IisWebsiteID
{
    <#
    .SYNOPSIS
    Sets a website's ID to an explicit number.

    .DESCRIPTION
    IIS handles assigning websites individual IDs.  This method will assign a website explicit ID you manage (e.g. to support session sharing in a web server farm).

    If another site already exists with that ID, you'll get an error.

    When you change a website's ID, IIS will stop the site, but not start the site after saving the ID change. This function waits until the site's ID is changed, and then will start the website.

    .EXAMPLE
    Set-IisWebsiteID -SiteName Holodeck -ID 483

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

    if( -not (Test-IisWebsite -Name $SiteName) )
    {
        Write-Error ('Website {0} not found.' -f $SiteName)
        return
    }

    $websiteWithID = Get-IisWebsite | Where-Object { $_.ID -eq $ID -and $_.Name -ne $SiteName }
    if( $websiteWithID )
    {
        Write-Error -Message ('ID {0} already in use for website {1}.' -f $ID,$SiteName) -Category ResourceExists
        return
    }

    $website = Get-IisWebsite -SiteName $SiteName
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
        $website = Get-IisWebsite -SiteName $SiteName
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
        $website = Get-IisWebsite -SiteName $SiteName
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