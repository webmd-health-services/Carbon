
function Get-WhiskeyApiKey
{
    <#
    .SYNOPSIS
    Gets an API key from the Whiskey API key store.

    .DESCRIPTION
    The `Get-WhiskeyApiKey` function returns an API key from Whiskey's API key store. If the API key doesn't exist, the current build stops (i.e. a terminating exception is thrown).

    Credentials are identified by an ID that you create. Credentials are added using `Add-WhiskeyCredential`. Credentials are used by tasks. You specify the credential's ID in tasks section of the `whiskey.yml` file. See the documentation for each task for more details.
    API keys are identified by an ID that you create. API keys are added using `Add-WhiskeyApiKey`. API keys are used by tasks. You specify the API keys' ID in the task's section of the `whiskey.yml` file. See the documentation for each task for more details.

    .EXAMPLE
    Get-WhiskeyApiKey -Context $context -ID 'nuget.org' -PropertyName 'ApiKeyID'

    Demonstrates how to get an API key. IN this case, retrieves the API key that was added with the ID `nuget.org`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The current build context. Use `New-WhiskeyContext` to create context objects.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The ID of the API key. You make this up.
        $ID,

        [Parameter(Mandatory=$true)]
        [string]
        # The property name in the task that needs this API key. Used in error messages to help users pinpoint what task and property might be misconfigured.
        $PropertyName
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $Context.ApiKeys.ContainsKey($ID) )
    {
        Stop-WhiskeyTask -TaskContext $Context `
                         -Message ('API key ''{0}'' does not exist in Whiskey''s API key store. Use the `Add-WhiskeyApiKey` function to add this API key, e.g. `Add-WhiskeyApiKey -Context $context -ID ''{0}'' -Value $apikey`.' -f $ID) `
                         -PropertyName $PropertyName
    }
    
    return $Context.ApiKeys[$ID]
}