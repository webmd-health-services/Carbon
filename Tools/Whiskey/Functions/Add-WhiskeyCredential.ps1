
function Add-WhiskeyCredential
{
    <#
    .SYNOPSIS
    Adds credential to Whiskey's credential store.

    .DESCRIPTION
    The `Add-WhiskeyCredential` function adds a credential to Whiskey's credential store. Tasks that need credentials usually have a property where you provide the ID of the credential. You provide Whiskey the value of that credential with this function.

    For example, if you are publishing a ProGet universal pakcage, your `whiskey.yml` file will look something like this:

        Publish:
        - PublishProGetUniversalPackage:
            Uri: https://proget.example.com
            FeedName: 'upack'
            CredentialID: ProgetExampleCom

    After you create your build's context with `New-WhiskeyContext`, you would then call `Add-WhiskeyCredential` to add the actual credential:

        $context = New-WhiskeyContext
        Add-WhiskeyCredential -Context $context -ID 'ProgetExampleCom' -Credential $credential
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The context of the build that needs the API key.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The ID of the credential. This should match the ID given in your `whiskey.yml` of credential ID property of the task that needs it.
        $ID,

        [Parameter(Mandatory=$true)]
        [pscredential]
        # The value of the credential.
        $Credential
    )

    Set-StrictMode -Version 'Latest'

    $Context.Credentials[$ID] = $Credential
}