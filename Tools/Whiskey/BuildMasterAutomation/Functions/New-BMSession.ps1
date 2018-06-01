
function New-BMSession
{
    <#
    .SYNOPSIS
    Creates a session object used to communicate with a BuildMaster instance.

    .DESCRIPTION
    The `New-BMSession` function creates and returns a session object that is required when calling any function in the BuildMasterAutomation module that communicates with BuildMaster. The session includes BuildMaster's URI and the credentials to use when making using BuildMaster's API.

    .EXAMPLE
    $session = New-BMSession -Uri 'https://buildmaster.com' -Credential $credential

    Demonstrates how to call `New-BMSession`. In this case, the returned session object can be passed to other BuildMasterAutomation module function to communicate with BuildMaster at `https://buildmaster.com` with the credential in `$credential`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [uri]
        # The URI to the BuildMaster instance to use.
        $Uri,

        [Parameter(Mandatory=$true)]
        [string]
        # The API key to use when making requests to BuildMaster.
        $ApiKey
    )

    Set-StrictMode -Version 'Latest'

    return [pscustomobject]@{
                                Uri = $Uri;
                                ApiKey = $ApiKey;
                            }
}