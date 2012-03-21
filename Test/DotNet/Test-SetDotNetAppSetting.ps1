$appSettingName = "TEST_APP_SETTING_NAME"
$appSettingValue = "TEST_APP_SETTING_VALUE"
$appSettingNewValue = "TEST_APP_SETTING_VALUE"

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    Remove-AppSetting
}

function TearDown
{
    Remove-AppSetting
    Remove-Module Carbon
}

function Remove-AppSetting
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        $appSettings = $config.AppSettings.Settings
        if( $appSettings[$Name] )
        {
            $appSettings.Remove( $Name )
            $config.Save()
        }
    }
    
    Invoke-PowerShell -Command $command -Args $appSettingName -x86
    Invoke-PowerShell -Command $command -Args $appSettingName 
}

function Test-ShouldSetAppSetting64
{
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework64
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework64
    Assert-AppSetting -Name $appSettingName -Value $null -Framework
}


function Test-ShouldSetAppSetting32
{
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework
    Assert-AppSetting -Name $appSettingName -Value $null -Framework64
}


function Test-ShouldSetAppSettingBoth
{
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework -Framework64
    Assert-AppSetting -Name $appSettingName -Value $appSettingValue -Framework  -Framework64
}

function Test-ShouldUpdateAppSetting
{
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -Framework -Framework64
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingNewValue -Framework -Framework64
    Assert-AppSetting -Name $appSettingName -Value $appSettingNewValue -Framework  -Framework64
}

function Test-ShouldRequireAFrameworkFlag
{
    $error.Clear()
    Set-DotNetAppSetting -Name $appSettingName -Value $appSettingValue -ErrorACtion SilentlyContinue
    Assert-Equal 1 $error.Count
}

function Assert-AppSetting($Name, $value, [Switch]$Framework, [Switch]$Framework64)
{
    $command = {
        param(
            $Name
        )
        
        Add-Type -AssemblyName System.Configuration
        
        $config = [Configuration.ConfigurationManager]::OpenMachineConfiguration()
        
        $appSettings = $config.AppSettings.Settings
        
        if( $appSettings[$Name] )
        {
            $appSettings[$Name].Value
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