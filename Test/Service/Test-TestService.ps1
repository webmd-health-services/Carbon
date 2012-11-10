
function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)    
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldFindExistingServices
{
    $error.Clear()
    $missingServices = Get-Service | 
                            Where-Object { -not (Test-Service -Name $_.Name) }
    Assert-Null $missingServices
    Assert-Equal 0 $error.Count
}

function Test-ShouldNotFindMissingService
{
    $error.Clear()
    Assert-False (Test-Service -Name 'ISureHopeIDoNotExist')
    Assert-Equal 0 $error.Count
}