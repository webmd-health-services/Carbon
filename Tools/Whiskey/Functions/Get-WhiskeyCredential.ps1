
function Get-WhiskeyCredential
{
    <#
    .SYNOPSIS
    Gets a credential from the Whiskey credential store.

    .DESCRIPTION
    The `Get-WhiskeyCredential` function returns a credential from Whiskey's credential store. If the credential doesn't exist, the current build stops (i.e. a terminating exception is thrown).

    Credentials are identified by an ID that you create. Credentials are added using `Add-WhiskeyCredential`. Credentials are used by tasks. You specify the credential's ID in the task's section of the `whiskey.yml` file. See the documentation for each task for more details.

    .EXAMPLE
    Get-WhiskeyCredential -Context $context -ID 'bitbucketserver.example.com' -PropertyName 'CredentialID'

    Demonstrates how to get a credential. IN this case, retrieves the credential that was added with the ID `bitbucketserver.example.com`.    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [object]
        # The current build context. Use `New-WhiskeyContext` to create context objects.
        $Context,

        [Parameter(Mandatory=$true)]
        [string]
        # The ID of the credential. You make this up.
        $ID,

        [Parameter(Mandatory=$true)]
        [string]
        # The property name in the task that needs this credential. Used in error messages to help users pinpoint what task and property might be misconfigured.
        $PropertyName,

        [string]
        # INTERNAL. DO NOT USE.
        $PropertyDescription
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -SessionState $ExecutionContext.SessionState

    if( -not $Context.Credentials.ContainsKey($ID) )
    {
        $propertyDescriptionParam = @{ }
        if( $PropertyDescription )
        {
            $propertyDescriptionParam['PropertyDescription'] = $PropertyDescription
        }
        Stop-WhiskeyTask -TaskContext $Context `
                         -Message ('Credential ''{0}'' does not exist in Whiskey''s credential store. Use the `Add-WhiskeyCredential` function to add this credential, e.g. `Add-WhiskeyCredential -Context $context -ID ''{0}'' -Credential $credential`.' -f $ID) `
                         @propertyDescriptionParam
    }

    return $Context.Credentials[$ID]
}