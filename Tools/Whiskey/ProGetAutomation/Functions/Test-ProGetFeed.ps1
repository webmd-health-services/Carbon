
function Test-ProGetFeed
{
    <#
    .SYNOPSIS
    Determines whether the specified package feed exists in a Proget instance.

    .DESCRIPTION
    The `Test-ProGetFeed` function will return `$true` if the requested package feed already exists. The function utilizes ProGet's native API and uses the API key of a `ProGetSession` instead of the preferred PSCredential authentication.

    .EXAMPLE
    Test-ProGetFeed -Session $ProGetSession -FeedName 'Apps' -FeedType 'ProGet'

    Demonstrates how to call `Test-ProGetFeed`. In this case, a value of `$true` will be returned if a Universal package feed named 'Apps' exists. Otherwise, `$false`
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [pscustomobject]
        # The session includes ProGet's URI and the API key. Use `New-ProGetSession` to create session objects
        $Session,

        [Parameter(Mandatory=$true)]
        [string]
        # The feed name indicates the name of the package feed that will be created.
        $FeedName,

        [Parameter(Mandatory=$true)]
        [string]
        # The feed type indicates the type of package feed to create.
        # Valid feed types are ('VSIX', 'RubyGems', 'Docker', 'ProGet', 'Maven', 'Bower', 'npm', 'Deployment', 'Chocolatey', 'NuGet', 'PowerShell') - check here for a latest list - https://inedo.com/support/documentation/proget/feed-types/universal
        $FeedType
    )

    Set-StrictMode -Version 'Latest'

    $proGetPackageUri = [String]$Session.Uri
    if (!$Session.ApiKey)
    {
        Write-Error -Message ('Failed to test for package feed ''{0}/{1}''. This function uses the ProGet Native API, which requires an API key. When you create a ProGet session with `New-ProGetSession`, provide an API key via the `ApiKey` parameter' -f $FeedType, $FeedName)
        return
    }
    $proGetApiKey = $Session.ApiKey

    $Parameters = @{}
    $Parameters['FeedType_Name'] = $FeedType
    $Parameters['Feed_Name'] = $FeedName

    $feedExists = Invoke-ProGetNativeApiMethod -Session $Session -Name 'Feeds_GetFeed' -Parameter $Parameters
    if($feedExists -match 'Feed_Id')
    {
        return $true
    }
    return $false
}
