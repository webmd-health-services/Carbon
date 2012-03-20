

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldCreateCredential
{
    $cred = New-Credential -User 'Credential' -Password 'password1'
    Assert-IsNotNull $cred 'New-Credential didn''t create credential object.'
    Assert-Is $cred 'Management.Automation.PSCredential' "didn't create credential object of right type"
    Assert-Equal 'Credential' $cred.UserName 'username not set correctly'
    Assert-NotEmpty (ConvertFrom-SecureString $cred.Password) 'password not set correctly'
}