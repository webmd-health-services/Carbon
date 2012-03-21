
function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldGetPowerShellPath
{
    $expectedPath = Join-Path $PSHome powershell.exe
    Assert-Equal $expectedPath (Get-PowerShellPath)
}

function Test-ShouldGet32BitPowerShellPath
{
    $expectedPath = Join-Path $PSHome powershell.exe
    if( Test-OSIs64Bit )
    {
        $expectedPath = $expectedPath -replace 'System32','SysWOW64'
    }
    
    Assert-Equal $expectedPath (Get-PowerShellPath -x86)
}