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
    if( $website.ID -ne $ID )
    {
        if( $PSCmdlet.ShouldProcess( ('website {0}' -f $SiteName), ('set site ID to {0}' -f $ID) ) )
        {
            Write-Host ('IIS:/{0}: setting site ID: {1} -> {2}' -f $SiteName,$website.ID,$ID)
            $website.ID = $ID
            $website.CommitChanges()
        }
    }
}