
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldNotFindNonExistentWebsite
{
    $result = Test-IisWebsiteExists 'jsdifljsdflkjsdf'
    Assert-False $result "Found a non-existent website!"
}

function Test-ShouldFindExistentWebsite
{
    Install-IisWebsite -Name 'Test Website Exists' -Path $TestDir
    try
    {
        $result = Test-IisWebsiteExists 'Test Website Exists'
        Assert-True $result "Did not find existing website."
    }
    finally
    {
        Remove-IisWebsite 'Test Website Exists'
    }
}
