
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldNotFindNonExistentAppPool
{
    $exists = Test-IisAppPoolExists -Name 'ANameIMadeUpThatShouldNotExist'
    Assert-False $exists "A non-existent app pool exists."
}

function Test-ShouldFindAppPools
{
    $apppools = Invoke-AppCmd list apppool
    Assert-GreaterThan $apppools.Length 0 "There aren't any app pools on the current machine!"
    foreach( $apppool in $apppools )
    {
        if( $apppool -notmatch "^APPPOOL ""([^""]+)" )
        {
            Fail "Unable to find app pool name: $apppool"
        }
        
        $appPoolName = $matches[1]
        $exists = Test-IisAppPoolExists -Name $appPoolName
        Assert-True $exists "An existing app pool '$appPoolName' not found."
    }
}