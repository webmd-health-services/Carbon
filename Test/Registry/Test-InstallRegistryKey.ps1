
$rootKey = 'hklm:\Software\Carbon\Test'

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    
    if( -not (Test-Path $rootKey -PathType Container) )
    {
        New-Item $rootKey -ItemType RegistryKey -Force
    }
    
}

function TearDown
{
    Remove-Module Carbon
    
    Remove-Item $rootKey -Recurse
}

function Test-ShouldCreateKey
{
    $keyPath = Join-Path $rootKey 'Test-InstallRegistryKey\ShouldCreateKey'
    if( Test-Path $keyPath -PathType Container )
    {
        Remove-Item $keyPath -Recurse
    }
    
    Install-RegistryKey -Path $keyPath
    
    Assert-True (Test-Path $keyPath -PathType Container)
}

function Test-ShouldDoNothingIfKeyExists
{
    $keyPath = Join-Path $rootKey 'Test-InstallRegistryKey\ShouldDoNothingIfKeyExists'
    Install-RegistryKey -Path $keyPath
    $subKeyPath = Join-Path $keyPath 'SubKey'
    Install-RegistryKey $subKeyPath
    Install-RegistryKey -Path $keyPath
    Assert-True (Test-Path $subKeyPath -PathType Container)
}

function Test-ShouldSupportShouldProcess
{
    $keyPath = Join-Path $rootKey 'Test-InstallRegistryKey\WhatIf'
    Install-RegistryKey -Path $keyPath -WhatIf
    Assert-False (Test-Path -Path $keyPath -PathType Container)
}