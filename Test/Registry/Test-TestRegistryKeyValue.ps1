
$rootKey = 'hklm:\Software\Carbon\Test\Test-TestRegistryKeyValue'

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    
    if( -not (Test-Path $rootKey -PathType Container) )
    {
        New-Item $rootKey -ItemType RegistryKey -Force
    }
    
    New-ItemProperty -Path $rootKey -Name 'Empty' -Value '' -PropertyType 'String'
    New-ItemProperty -Path $rootKey -Name 'Null' -Value $null -PropertyType 'String'
    New-ItemProperty -Path $rootKey -Name 'State' -Value 'Foobar''ed' -PropertyType 'String'
}

function TearDown
{
    Remove-Module Carbon
    
    Remove-Item $rootKey -Recurse
}

function Test-ShouldDetectValueWithEmptyValue
{
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name 'Empty')
}

function Test-ShouldDetectValueWithNullValue
{
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name 'Null')
}

function Test-ShouldDetectValueWithAValue
{
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name 'State')
}

function Test-ShouldDetectNoValueInMissingKey
{
    Assert-False (Test-RegistryKeyValue -Path (Join-Path $rootKey fjdsklfjsadf) -Name 'IDoNotExistEither')
}

function Test-ShouldNotDetectMissingValue
{
    Set-StrictMode -Version Latest
    $error.Clear()
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'BlahBlahBlah' -ErrorAction SilentlyContinue)
    Assert-Equal 0 $error.Count
}

function Test-ShouldHandleKeyWithNoValues
{
    Remove-ItemProperty -Path $rootKey -Name *
    $error.Clear()
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name 'Empty')
    Assert-Equal 0 $error.Count
}
