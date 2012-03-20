
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldCheckIfLocalAccountExists
{
    $localUserAccounts = @(Get-WmiObject -Query "select * from win32_useraccount where Domain='$($env:ComputerName)'" -Computer .)
    Assert-True (0 -lt $localUserAccounts.Length)
    foreach( $localUserAccount in $localUserAccounts )
    {
        Assert-True (Test-User -Username $localUserAccount.Name)
    }
}

function Test-ShouldNotFindNonExistentAccount
{
    $error.Clear()
    Assert-False (Test-User -Username ([Guid]::NewGuid().ToString().Substring(0,20)))
    Assert-False $error
}