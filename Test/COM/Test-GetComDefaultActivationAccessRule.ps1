
function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetComDefaultAccessRule
{
    $rules = Get-ComDefaultActivationAccessRule
    Assert-NotNull $rules
    $rules | ForEach-Object { 
        Assert-NotNull $_.IdentityReference
        Assert-NotNull $_.ComAccessRights
        Assert-NotNull $_.AccessControlType
        Assert-False $_.IsInherited
        Assert-Equal 'None' $_.InheritanceFlags
        Assert-Equal 'None' $_.PropagationFlags
     }
}