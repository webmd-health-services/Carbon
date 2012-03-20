
$EnvVarName = "CarbonRemoveEnvironmentVar"

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon)
}

function TearDown
{
    @( 'Machine', 'User', 'Process') | % { Remove-EnvironmentVariable -Name $EnvVarName -Scope $_ }
    Remove-Module Carbon
}

function Set-TestEnvironmentVariable($Scope)
{
    $EnvVarValue = [Guid]::NewGuid().ToString()
    [Environment]::SetEnvironmentVariable($EnvVarName, $EnvVarValue, $Scope)
    
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope) 
    Assert-Equal $EnvVarValue $actualValue "$Scope environment variable not set."
    
    return $EnvVarValue
}

function Test-ShouldRemoveMachineEnvironmentVar
{
    Set-TestEnvironmentVariable 'Machine'
    Remove-EnvironmentVariable -Name $EnvVarName -Scope Machine
    Assert-NoTestEnvironmentVariableAt -Scope Machine
}

function Test-ShouldRemoveUserEnvironmentVar
{
    Set-TestEnvironmentVariable 'User'
    
    Assert-NoTestEnvironmentVariableAt -Scope Machine
    
    Remove-EnvironmentVariable -Name $EnvVarName -Scope User

    Assert-NoTestEnvironmentVariableAt -Scope User
}

function Test-ShouldRemoveProcessEnvironmentVar
{
    Set-TestEnvironmentVariable 'Process'
    
    Assert-NoTestEnvironmentVariableAt -Scope Machine
    Assert-NoTestEnvironmentVariableAt -Scope User
    
    Remove-EnvironmentVariable -Name $EnvVarName -Scope Process

    Assert-NoTestEnvironmentVariableAt -Scope Process
}

function Test-ShouldRemoveNonExistentEnvironmentVar
{
    Remove-EnvironmentVariable -Name "IDoNotExist" -Scope Machine
}

function Test-ShouldSupportWhatIf
{
    $envVarValue = Set-TestEnvironmentVariable -Scope Process
    
    Remove-EnvironmentVariable -Name $EnvVarName -Scope Process -WhatIf
    
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, 'Process') 
    Assert-NotNull $actualValue "WhatIf parameter resulted in environment variable being deleted."
    Assert-Equal $actualValue $envVarValue "WhatIf parameter resulted in environment variable being deleted."
}

function Assert-NoTestEnvironmentVariableAt( $Scope )
{
    $actualValue = [Environment]::GetEnvironmentVariable($EnvVarName, $Scope)
    Assert-Null $actualValue "Environment variable '$EnvVarName' found at scope $Scope."
}