
$EnvVarName = 'CarbonTestSetEnvironmentVariable'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon)
}

function TearDown
{
    @( 'Machine', 'User', 'Process' ) | % { Remove-EnvironmentVariable -Name $EnvVarName -Scope $_ }
    Remove-Module Carbon
}

function Set-TestEnvironmentVariable($Scope)
{
    $value = [Guid]::NewGuid().ToString()
    Set-EnvironmentVariable -Name $EnvVarName -Value $value -Scope $Scope
    Assert-TestEnvironmentVariableIs -ExpectedValue $value -Scope $Scope
    return $value
}

function Test-ShouldSetEnvironmentVariableAtMachineScope
{
    Set-TestEnvironmentVariable -Scope Machine
}

function Test-ShouldSetEnvironmentVariableAtUserScope
{
    Set-TestEnvironmentVariable -Scope User
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Machine'
}

function Test-ShouldSetEnvironmentVariableAtProcessScope
{
    Set-TestEnvironmentVariable -Scope Process
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Machine'
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'User'
}

function Test-ShouldNotSetVariableIfWhatIf
{
    Set-EnvironmentVariable -Name $EnvVarName -Value 'Doesn''t matter.' -Scope 'Process' -WhatIf
    Assert-TestEnvironmentVariableIs -ExpectedValue $null -Scope 'Process'
}

function Assert-TestEnvironmentVariableIs($ExpectedValue, $Scope)
{
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope)
    Assert-Equal $ExpectedValue $actualValue "Environment variable not set at $Scope scope."
    
}