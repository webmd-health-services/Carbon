
$username = 'CarbonRemoveUser'
$password = [Guid]::NewGuid().ToString().Substring(0,14)

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon)
    net user $username $password /add
}

function TearDown
{
    if( Test-User -Username $username )
    {
        net user $username /delete
    }
    Remove-Module Carbon
}

function Test-ShouldRemoveUser
{
    Remove-User -Username $username
    Assert-False (Test-User -Username $username)
}

function Test-ShouldHandleRemovingNonExistentUser
{
    $error.Clear()
    Remove-User -Username ([Guid]::NewGuid().ToString().Substring(0,20))
    Assert-False $error
}

function Test-ShouldSupportWhatIf
{
    Remove-User -Username $username -WhatIf
    Assert-True (Test-User -Username $username)
}
