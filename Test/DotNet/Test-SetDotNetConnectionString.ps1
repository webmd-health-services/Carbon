$connectionStringName = "TEST_CONNECTION_STRING_NAME"
$connectionStringValue = "TEST_CONNECTION_STRING_VALUE"
$connectionStringNewValue = "TEST_CONNECTION_STRING_NEW_VALUE"

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Remove-ConnectionStrings    
}

function TearDown
{
    Remove-ConnectionStrings
    Remove-Module Carbon
}

function Remove-ConnectionStrings
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        $connectionStrings = $config.ConnectionStrings.ConnectionStrings
        if( $connectionStrings[$Name] )
        {
            $connectionStrings.Remove( $Name )
            $config.Save()
        }
    }
    
    Invoke-PowerShell -Command $command -Args $connectionStringName -x86
    Invoke-PowerShell -Command $command -Args $connectionStringName 
}

function Test-ShouldAddConnectionString64
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework64
    Assert-ConnectionString -Name $connectionStringName -Value $null -Framework
}

function Test-ShouldAddConnectionString32
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework
    Assert-ConnectionString -Name $connectionStringName -Value $null -Framework64   
}

function Test-ShouldAddConnectionStringBoth
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Framework64
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Framework64
}

function Test-ShouldUpdateConnectionString
{
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -Framework -Framework64
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Framework64
    Assert-ConnectionString -Name $connectionStringName -Value $connectionStringNewValue -Framework -Framework64
}

function Test-ShouldRequireAFrameworkFlag
{
    $error.Clear()
    Set-DotNetConnectionString -Name $connectionStringName -Value $connectionStringValue -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
}

function Assert-ConnectionString($Name, $value, [Switch]$Framework, [Switch]$Framework64)
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        $connectionStrings = $config.ConnectionStrings.ConnectionStrings
        
        if( $connectionStrings[$Name] )
        {
            $connectionStrings[$Name].ConnectionString
        }
        else
        {
            $null
        }
    }
    
    if( $Framework64 )
    {
        $actualValue = Invoke-PowerShell -Command $command -Args $Name
        Assert-Equal $Value $actualValue
    }
    
    if( $Framework )
    {
        $actualValue = Invoke-PowerShell -Command $command -Args $Name -x86
        Assert-Equal $Value $actualValue
    }
}