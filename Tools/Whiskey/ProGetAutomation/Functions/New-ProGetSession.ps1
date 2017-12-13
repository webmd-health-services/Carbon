
function New-ProGetSession
{
    <#
    .SYNOPSIS
    Creates a session object used to communicate with a ProGet instance.

    .DESCRIPTION
    The `New-ProGetSession` function creates and returns a session object that is required when calling any function in the ProGetAutomation module that communicates with ProGet. The session includes ProGet's URI and the credentials to use when utilizing ProGet's API.

    .EXAMPLE
    $session = New-ProGetSession -Uri 'https://proget.com' -Credential $credential

    Demonstrates how to call `New-ProGetSession`. In this case, the returned session object can be passed to other ProGetAutomation module functions to communicate with ProGet at `https://proget.com` with the credential in `$credential`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [uri]
        # The URI to the ProGet instance to use.
        $Uri,

        [pscredential]
        # The credential to use when making requests to ProGet utilizing the Universal Feed API.
        $Credential,

        [string]
        # The API key to use when making requests to ProGet utilizing the Native API
        $ApiKey
    )

    Set-StrictMode -Version 'Latest'

    return [pscustomobject]@{
                                Uri = $Uri;
                                Credential = $Credential;
                                ApiKey = $ApiKey
                            }
}
