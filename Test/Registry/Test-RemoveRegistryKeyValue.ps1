
$rootKey = 'hklm:\Software\Carbon\Test\Test-RemoveRegistryKeyValue'
$valueName = 'RegValue'

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

function Test-ShouldRemoveExistingRegistryValue
{
    New-ItemProperty $rootKey -Name $valueName -Value 'it doesn''t matter' -PropertyType 'String'
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
    Remove-RegistryKeyValue -Path $rootKey -Name $valueName
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
}

function Test-ShouldRemoveNonExistentRegistryValue
{
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'I do not exist')
    Remove-RegistryKeyValue -Path $rootKey -Name 'I do not exist'
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'I do not exist')
}

function Test-ShouldSupportWhatIf
{
    New-ItemProperty $rootKey -Name $valueName -Value 'it doesn''t matter' -PropertyType 'String'
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
    Remove-RegistryKeyValue -Path $rootKey -Name $valueName -WhatIf
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $valueName)
}