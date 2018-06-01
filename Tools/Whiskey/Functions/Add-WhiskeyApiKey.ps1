
function Add-WhiskeyApiKey
{
    <#
    .SYNOPSIS
    Adds an API key to Whiskey's API key store.

    .DESCRIPTION
    The `Add-WhiskeyApiKey` function adds an API key to Whiskey's API key store. Tasks that need API keys usually have a property where you provide the ID of the API key to use. You provide Whiskey the value of the API Key with this function.

    For example, if you are publishing a PowerShell module, your `whiskey.yml` file will look something like this:

        Publish:
        - PublishPowerShellModule:
            RepositoryName: PSGallery
            Path: Whiskey
            ApiKeyID: PSGalleryApiKey

    After you create your build's context with `New-WhiskeyContext`, you would then call `Add-WhiskeyApiKey` to add the actual API key:

        $context = New-WhiskeyContext
        Add-WhiskeyApiKey -Context $context -ID 'PSGalleryApiKey' -Value '901a072f-fe5e-44ec-8546-029ffbec0687'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context of the build that needs the API key.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The ID of the API key. This should match the ID given in your `whiskey.yml` for the API key ID property of the task that needs it.
        $ID,

        [Parameter(Mandatory=$true)]
        [string]
        # The value of the API key.
        $Value
    )

    Set-StrictMode -Version 'Latest'

    $Context.ApiKeys[$ID] = $Value
}