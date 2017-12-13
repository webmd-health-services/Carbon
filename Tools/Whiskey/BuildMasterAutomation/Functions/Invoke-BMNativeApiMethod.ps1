
function Invoke-BMNativeApiMethod
{
    <#
    .SYNOPSIS
    Calls a method on BuildMaster's "native" API.

    .DESCRIPTION
    The `Invoke-BMNativeApiMethod` calls a method on BuildMaster's "native" API. From Inedo:

    > This API endpoint should be avoided if there is an alternate API endpoint available, as those are much easier to use and will likely not change.

    In other words, use a native API at your own peril.

    .EXAMPLE
    Invoke-BMNativeApiMethod -Session $session -Name 'Applications_CreateApplication' -Parameter @{ Application_Name = 'fubar' }

    Demonstrates how to call `Invoke-BMNativeApiMethod`. In this example, it is calling the `Applications_CreateApplication` method to create a new application named `fubar`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # A session object that represents the BuildMaster instance to use. Use the `New-BMSession` function to create session objects.
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the API method to use. The list can be found at http://inedo.com/support/documentation/buildmaster/reference/api/native, or under your local BuildMaster instance at /reference/api
        $Name,

        [Microsoft.PowerShell.Commands.WebRequestMethod]
        # The HTTP/web method to use. The default is `POST`.
        $Method = [Microsoft.PowerShell.Commands.WebRequestMethod]::Post,

        [Parameter(Mandatory=$true)]
        [hashtable]
        $Parameter
    )

    Set-StrictMode -Version 'Latest'

    Invoke-BMRestMethod -Session $Session -Name ('json/{0}' -f $Name) -Method $Method -Parameter $Parameter -AsJson

}