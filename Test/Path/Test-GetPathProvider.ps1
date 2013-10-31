
function Start-Test
{
    & (Join-Path -Path $TestDir -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Stop-Test
{
}

function Test-ShouldGetFileSystemProvider
{
    Assert-Equal 'FileSystem' ((Get-PathProvider -Path 'C:\Windows').Name)
}

function Test-ShouldGetRelativePathProvider
{
    Assert-Equal 'FileSystem' ((Get-PathProvider -Path '..\').Name)
}

function Test-ShouldGetRegistryProvider
{
    Assert-Equal 'Registry' ((Get-PathProvider -Path 'hklm:\software').Name)
}

function Test-ShouldGetRelativePathProvider
{
    Push-Location 'hklm:\SOFTWARE\Microsoft'
    try
    {
        Assert-Equal 'Registry' ((Get-PathProvider -Path '..\').Name)
    }
    finally
    {
        Pop-Location
    }
}

function Test-ShouldGetNoProviderForBadPath
{
    Assert-Equal 'FileSystem' ((Get-PathProvider -Path 'C:\I\Do\Not\Exist').Name)
}
