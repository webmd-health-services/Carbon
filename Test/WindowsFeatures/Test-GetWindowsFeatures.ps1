
function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldReturnAllWindowsFeatures
{
    $features = Get-WindowsFeature
    Assert-NotNull $features
    Assert-True ($features.Length -gt 1)
    $features | ForEach-Object {
        Assert-NotNull $_.Installed
        Assert-NotNull $_.Name
        Assert-NotNull $_.DisplayName
    }
}

function Test-ShouldReturnSpecificFeature
{
    Get-WindowsFeature | ForEach-Object {
        $expectedFeature = $_
        $feature = Get-WindowsFeature -Name $expectedFeature.Name
        Assert-NotNull $feature
        Assert-Equal $expectedFeature.Name $feature.Name
        Assert-Equal $expectedFeature.DisplayName $feature.DisplayName
        Assert-Equal $expectedFeature.Installed $feature.Installed
    }
}

function Test-ShouldReturnWildcardMatches
{
    $features = Get-WindowsFeature -Name *msmq*
    Assert-NotNull $features
    $features | ForEach-Object {
        Assert-NotNull $_.Installed
        Assert-NotNull $_.Name
        Assert-True ($_.Name -like '*msmq*')
        Assert-NotNull $_.DisplayName
    }
}
