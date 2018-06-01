
function New-ProGetFeed
{
    <#
    .SYNOPSIS
    Creates a new ProGet package feed

    .DESCRIPTION
    The `New-ProGetFeed` function creates a new ProGet feed. Use the `FeedType` parameter to specify the feed type (valid values are 'VSIX', 'RubyGems', 'Docker', 'ProGet', 'Maven', 'Bower', 'npm', 'Deployment', 'Chocolatey', 'NuGet', 'PowerShell'). The `Session` parameter controls the instance of ProGet to connect to. This function uses ProGet's Native API, so an API key is required. Use `New-ProGetSession` to create a session with your API key.

    .EXAMPLE
    New-ProGetFeed -Session $ProGetSession -FeedName 'Apps' -FeedType 'ProGet'

    Demonstrates how to call `New-ProGetFeed`. In this case, a new Universal package feed named 'Apps' will be created for the specified ProGet Uri
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
        Write-Error -Message ('We are unable to create new package feed ''{0}/{1}'' because your ProGet session is missing an API key. This function uses ProGet''s Native API, which requires an API key. Use `New-ProGetSession` to create a session object that uses an API key.' -f $FeedType, $FeedName)
        return
    }
    $proGetApiKey = $Session.ApiKey

    $Parameters = @{}
    $Parameters['FeedType_Name'] = $FeedType
    $Parameters['Feed_Name'] = $FeedName

    $feedExists = Test-ProGetFeed -Session $Session -FeedName $FeedName -FeedType $FeedType
    if($feedExists)
    {
        Write-Error -Message ('Unable to create feed ''{0}/{1}''. A feed with that name already exists.' -f $FeedType, $FeedName) -ErrorAction $ErrorActionPreference
        return
    }
    $null = Invoke-ProGetNativeApiMethod -Session $Session -Name 'Feeds_CreateFeed' -Parameter $Parameters

    Write-Verbose -Message ('Successfully created new package feed ''{0}/{1}'' in ProGet instance ''{2}' -f $FeedType, $FeedName, $proGetPackageUri)
}
