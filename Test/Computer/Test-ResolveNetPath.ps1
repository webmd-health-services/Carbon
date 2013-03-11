
function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldFindPathToNetCommand
{
    $netPath = Resolve-NetPath
    Assert-NotNull $netPath
    Assert-Equal (Join-Path $env:windir system32\net.exe) $netPath
}
