
$username = 'CarbonComputerInstllUsr'
$password = [Guid]::NewGuid().ToString().Substring(0,14)

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
}

function TearDown
{
    if( Test-User -Username $username )
    {
        Remove-User -Username $username
    }
    Remove-Module Carbon
}

function Test-ShouldCreateNewUser
{
    $description = "Test user for testing the Carbon Install-User function."
    Install-User -Username $username -Password $password -Description $description
    Assert-True (Test-User -Username $username)
    $user = Get-User -Username $Username
    Assert-NotNull $user
    Assert-Equal $description $user.Description
    Assert-False $user.PasswordExpires 
}

function Test-ShouldUpdateExistingUsersProperties
{
    Install-User -Username $username -Password $password -Description "Original description"
    $originalUser = Get-User -Username $username
    Assert-NotNull $originalUser
    
    $newDescription = "New description"
    Install-User -Username $username -Password ([Guid]::NewGuid().ToString().Substring(0,14)) -Description $newDescription
    $newUser = Get-User -Username $username
    Assert-NotNull $newUser
    Assert-Equal $originalUser.SID $newUser.SID
    Assert-Equal $newDescription $newUser.Description
}

function Test-ShouldSupportWhatIf
{
    Install-User -Username $username -Password $password -WhatIf
    $user = Get-User -Username $username
    Assert-Null $user
}
