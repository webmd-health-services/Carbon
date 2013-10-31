
function Start-Test
{
    & (Join-Path -Path $TestDir -ChildPath '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Stop-Test
{
}

function Test-ShouldConvertFileSystemValue
{
    Assert-Equal ([Security.AccessControl.FileSystemRights]::Read) (ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read')
}

function Test-ShouldConvertFileSystemValues
{
    $expected = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Write
    $actual = ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'Read','Write'
    Assert-Equal $expected $actual
}

function Test-ShouldConvertFileSystemValueFromPipeline
{
    $expected = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Write
    $actual = 'Read','Write' | ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem'
    Assert-Equal $expected $actual
}

function Test-ShouldConvertRegistryValue
{
    $expected = [Security.AccessControl.RegistryRights]::Delete
    $actual = 'Delete' | ConvertTo-ProviderAccessControlRights -ProviderName 'Registry'
    Assert-Equal $expected $actual
}

function Test-ShouldHandleInvalidRightName
{
    $Error.Clear()
    Assert-Null (ConvertTo-ProviderAccessControlRights -ProviderName 'FileSystem' -InputObject 'BlahBlah','Read' -ErrorAction 'SilentlyContinue')
    Assert-Equal 1 $Error.Count
}