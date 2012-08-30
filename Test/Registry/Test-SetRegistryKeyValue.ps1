
$rootKey = 'hklm:\Software\Carbon\Test\Test-SetRegistryKeyValue'

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

function Test-ShouldCreateNewKeyAndValue
{
    $keyPath = Join-Path $rootKey 'ShouldCreateNewKeyAndValue'
    $name = 'Title'
    $value = 'This is Sparta!'
    
    Assert-False (Test-RegistryKeyValue -Path $keyPath -Name $name)
    Set-RegistryKeyValue -Path $keyPath -Name $name -String $value
    Assert-True (Test-RegistryKeyValue -Path $keyPath -Name $name)
    
    $actualValue = Get-RegistryKeyValue -Path $keyPath -Name $name
    Assert-Equal $value $actualValue
}

function Test-ShouldChangeAnExistingValue
{
    $name = 'ShouldChangeAnExistingValue'
    $value = 'foobar''ed'
    Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
    Assert-Equal $value (Get-RegistryKeyValue -Path $rootKey -Name $name)
    
    $newValue = 'Ok'
    Set-RegistryKeyValue -Path $rootKey -Name $name -String $newValue
    Assert-Equal $newValue (Get-RegistryKeyValue -Path $rootKey -Name $name)
}

function Test-ShouldSetBinaryValue
{
    Set-RegistryKeyValue -Path $rootKey -Name 'Binary' -Binary ([byte[]]@( 1, 2, 3, 4))
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'Binary'
    Assert-NotNull $value
    Assert-Equal 'System.Object[]' $value.GetType()
    Assert-Equal 1 $value[0]
    Assert-Equal 2 $value[1]
    Assert-Equal 3 $value[2]
    Assert-Equal 4 $value[3]
}

function Test-ShouldSetDwordValue
{
    $number = [Int32]::MaxValue
    Set-RegistryKeyValue -Path $rootKey -Name 'DWord' -DWord $number
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'DWord'
    Assert-NotNull $value
    Assert-Equal 'int' $value.GetType()
    Assert-Equal $number $value
}

function Test-ShouldSetQwordValue
{
    $number = [Int64]::MaxValue
    Set-RegistryKeyValue -Path $rootKey -Name 'QWord' -QWord $number
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'QWord'
    Assert-NotNull $value
    Assert-Equal 'long' $value.GetType()
    Assert-Equal $number $value
}

function Test-ShouldSetMultiStringValue
{
    $strings = @( 'Foo', 'Bar' )
    Set-RegistryKeyValue -Path $rootKey -Name 'Strings' -Strings $strings
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'Strings'
    Assert-NotNull $value
    Assert-Equal $strings.Length $value.Length
    Assert-Equal $strings[0] $value[0]
    Assert-Equal $strings[1] $value[1]
}

function Test-ShouldSetExpandingStringValue
{
    Set-RegistryKeyValue -Path $rootKey -Name 'Expandable' -String '%ComputerName%' -Expand
    $value = Get-RegistryKeyValue -Path $rootKey -Name 'Expandable'
    Assert-NotNull $value
    Assert-Equal $env:ComputerName $value
}

function Test-ShouldRemoveAndRecreateValue
{
    $name = 'ShouldChangeAnExistingValue'
    $value = 'foobar''ed'
    Set-RegistryKeyValue -Path $rootKey -Name $name -String $value
    Assert-Equal $value (Get-RegistryKeyValue -Path $rootKey -Name $name)
    
    $newValue = 8439
    Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $newValue -Force
    $newActualValue = Get-RegistryKeyValue -Path $rootKey -Name $name
    Assert-Equal $newValue $newActualValue
    Assert-Equal 'int' $newActualValue.GetType()
}

function Test-ShouldCreateNewValueEvenWithForce
{
    $name = 'NewWithForce'
    $value = 8439
    Assert-False (Test-REgistryKeyValue -Path $rootKey -Name $name)
    Set-RegistryKeyValue -Path $rootKey -Name $name -DWord $value -Force
    $actualValue = Get-RegistryKeyValue -Path $rootKey -Name $name
    Assert-Equal $value $actualValue
    Assert-Equal 'int' $actualValue.GetType()
}

function Test-ShouldSupportWhatIfWhenCReatingNewValue
{
    $name = 'newwithwhatif'
    $value = 'value'
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name $name)
    Set-REgistryKeyValue -Path $rootKey -Name $name -String $value -WhatIf
    Assert-False (Test-RegistryKeyValue -Path $rootKey -Name $name)
}

function Test-ShouldSupportWhatIfWhenUpdatingValue
{
    $name = 'newwithwhatif'
    $value = 'value'
    $newValue = 'newvalue'
    Set-REgistryKeyValue -Path $rootKey -Name $name -String $value
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $name)
    
    Set-REgistryKeyValue -Path $rootKey -Name $name -String $newValue -WhatIf
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $name)
    Assert-Equal $value (Get-REgistryKeyValue -Path $rootKey -Name $name)

    Set-REgistryKeyValue -Path $rootKey -Name $name -String $newValue -WhatIf -Force
    Assert-True (Test-RegistryKeyValue -Path $rootKey -Name $name)
    Assert-Equal $value (Get-REgistryKeyValue -Path $rootKey -Name $name)
}