
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetUser
{
    Get-WmiObject Win32_UserAccount -Filter "Domain='$($env:ComputerName)'" | ForEach-Object {
        $user = Get-User -Username $_.Name
        Assert-NotNull $user
        Assert-Equal $_.Name $user.Name
        Assert-Equal $_.FullName $user.FullName
        Assert-Equal $_.SID $user.SID
    }
}