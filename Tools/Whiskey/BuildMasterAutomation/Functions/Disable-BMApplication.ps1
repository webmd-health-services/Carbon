
function Disable-BMApplication
{
    <#
    .SYNOPSIS
    Disables a BuildMaster application
    
    .DESCRIPTION
    Disables an application in BuildMaster. This doesn't delete the application. Just removes it from the UI.

    This function uses the native API, which can change without notice between releases. The API key you use must have access to the native API.
    
    .EXAMPLE
    Disable-BMApplication -Session $session -ID 494

    Demonstrates how to delete an application using its ID.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The session to use when connecting to BuildMaster. Use `New-BMSession` to create session objects. 
        $Session,

        [Parameter(Mandatory=$true)]
        [int]
        # The name of the application to get. 
        $ID
    )

    Set-StrictMode -Version 'Latest'

    Invoke-BMNativeApiMethod -Session $Session -Name 'Applications_DeactivateApplication' -Parameter @{ Application_Id = $ID } -Method Post
}
