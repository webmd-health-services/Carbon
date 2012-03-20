
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetIISVersion
{
    $props = get-itemproperty hklm:\Software\Microsoft\InetStp
    $expectedVersion = $props.MajorVersion.ToString() + '.' + $props.MinorVersion.ToString()
    $actualVersion = Get-IISVersion
    Assert-Equal $expectedVersion $actualVersion "Didn't get the correct IIS version."
}