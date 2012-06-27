
function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldValidateFileIsAnMSI
{
    $error.Clear()
    Invoke-WindowsInstaller -Path (Join-Path $TestDir Test-InvokeWindowsInstaller.ps1 -Resolve) -Quiet -ErrorAction SilentlyContinue
    Assert-Equal 1 $error.Count
}

function Test-ShouldSupportWhatIf
{
    $fakeInstallerPath = Join-Path $TestDir FakeInstaller.msi -Resolve
    $error.Clear()
    Invoke-WindowsInstaller -Path $fakeInstallerPath -Quiet -WhatIf
    Assert-Equal 0 $error.Count
    Assert-Equal 0 $LastExitCode
}