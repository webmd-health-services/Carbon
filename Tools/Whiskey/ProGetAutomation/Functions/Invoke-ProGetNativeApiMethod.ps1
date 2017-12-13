
function Invoke-ProGetNativeApiMethod
{
    <#
    .SYNOPSIS
    Calls a method on ProGet's Native API.

    .DESCRIPTION
    The `Invoke-ProGetNativeApiMethod` calls a method on ProGet's Native API. From Inedo:

    > This API endpoint should be avoided if there is an alternate API endpoint available, as those are much easier to use and will likely not change.

    In other words, use a native API at your own peril.

    .EXAMPLE
    Invoke-ProGetNativeApiMethod -Session $session -Name 'Feeds_CreateOrUpdateProGetFeed' -Parameter @{ Feed_Name = 'Apps' }

    Demonstrates how to call `Invoke-ProGetNativeApiMethod`. In this example, it is calling the `Feeds_CreateOrUpdateProGetFeed` method to create a new Universal feed named `Apps`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the ProGet instance to use. Use the `New-ProGetSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the API method to use. The list can be found at `http://inedo.com/support/documentation/proget/reference/api/native` or in your ProGet installation at `/reference/api/native` 
        $Name,

        [hashtable]
        $Parameter
    )

    Set-StrictMode -Version 'Latest'

    if( -not $Parameter )
    {
        $Parameter = @{}
    }
    
    Invoke-ProGetRestMethod -Session $Session -Path ('/api/json/{0}' -f $Name) -Method Post -Parameter $Parameter -AsJson

}
