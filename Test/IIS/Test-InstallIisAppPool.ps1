
$appPoolName = 'PSAppPool'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve)
    Remove-AppPool
}

function TearDown
{
    Remove-AppPool
    Remove-Module Carbon
}

function Remove-AppPool
{
    if( (Test-IisAppPoolExists -Name $appPoolName) )
    {
        Invoke-AppCmd delete apppool `"$appPoolName`"
    }
}

function Get-IISDefaultAppPoolIdentity
{
    $iisVersion = Get-IISVersion
    if( $iisVersion -eq '7.0' )
    {
        return 'NetworkService'
    }
    return 'ApplicationPoolIdentity'
}

function Test-ShouldCreateNewAppPool
{
    Install-IisAppPool -Name $appPoolName
    Assert-AppPoolExists
    Assert-ManagedRuntimeVersion 'v4.0'
    Assert-ManagedPipelineMode 'Integrated'
    Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
    Assert-AppPool32BitEnabled $false
    Assert-IdleTimeout 0
}

function Test-ShouldSetManagedRuntimeVersion
{
    Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0'
    Assert-AppPoolExists
    Assert-ManagedRuntimeVersion 'v2.0'
}

function Test-ShouldSetManagedPipelineMode
{
    Install-IisAppPool -Name $appPoolName -ClassicPipelineMode
    Assert-AppPoolExists
    Assert-ManagedPipelineMode 'Classic'
}

function Test-ShouldSetIdentityAsServiceAccount
{
    Install-IisAppPool -Name $appPoolName -ServiceAccount 'NetworkService'
    Assert-AppPoolExists
    Assert-IdentityType 'NetworkService'
}

function Test-ShouldSetIdentityAsSpecificUser
{
    Install-IisAppPool -Name $appPoolName -UserName 'Administrator' -Password 'GoodLuckWithThat'
    Assert-AppPoolExists
    Assert-Identity 'Administrator' 'GoodLuckWithThat'
    Assert-IdentityType 'SpecificUser'
}

function Test-ShouldSetIdleTimeout
{
    Install-IisAppPool -Name $appPoolName -IdleTimeout 55
    Assert-AppPoolExists
    Assert-Idletimeout 55
}

function Test-ShouldEnable32bitApps
{
    Install-IisAppPool -Name $appPoolName -Enable32BitApps
    Assert-AppPoolExists
    Assert-AppPool32BitEnabled $true
}

function Test-ShouldHandleAppPoolThatExists
{
    Install-IisAppPool -Name $appPoolName
    Install-IisAppPool -Name $appPoolName
}

function Assert-AppPoolExists
{
    $exists = Test-IisAppPoolExists -Name $appPoolname
    Assert-True $exists "App pool '$appPoolName' not created."
}

function Test-ShouldChangeSettingsOnExistingAppPool
{
    Install-IisAppPool -Name $appPoolName
    Assert-AppPoolExists
    Assert-ManagedRuntimeVersion 'v4.0'
    Assert-ManagedPipelineMode 'Integrated'
    Assert-IdentityType (Get-IISDefaultAppPoolIdentity)

    Assert-AppPool32BitEnabled $false

    Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0' -ClassicPipeline -ServiceAccount 'LocalSystem' -Enable32BitApps
    Assert-AppPoolExists
    Assert-ManagedRuntimeVersion 'v2.0'
    Assert-ManagedPipelineMode 'Classic'
    Assert-IdentityType 'LocalSystem'
    Assert-AppPool32BitEnabled $true

}

function Test-ShouldAcceptSecureStringForAppPoolPassword
{
    $password = "HelloWorld"
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    $username = "$($env:computername)\SomeUser"
    Install-IisAppPool -Name $appPoolName -Username $username -Password $securePassword
    Assert-Identity $username $password
    
}

function Get-AppPoolDetails
{
    return Invoke-AppCmd list apppool /name:`"$appPoolname`"
}

function Assert-ManagedRuntimeVersion($Version)
{
    $apppool = Get-AppPoolDetails
    $correctVersion = $apppool -match "MgdVersion:$([Text.RegularExpressions.Regex]::Escape($Version))"
    Assert-True $correctVersion "App pool's managed runtime not at correct version."
}

function Assert-ManagedPipelineMode($expectedMode)
{
    $apppool = Get-AppPoolDetails
    $correctMode = $apppool -match "MgdMode:$expectedMode"
    Assert-True $correctMode "App pool's managed pipeline not in $expectedMode mode."
}

function Assert-IdentityType($expectedIdentityType)
{
    $identityType = Invoke-AppCmd list apppool $appPoolName /text:processModel.identityType
    Assert-Equal $expectedIdentityType $identityType 'App pool identity type not set correctly'
}

function Assert-IdleTimeout($expectedIdleTimeout)
{
    $idleTimeout = Invoke-AppCmd list apppool $appPoolName /text:processModel.idleTimeout
    $expectedIdleTimeoutTimespan = New-TimeSpan -minutes $expectedIdleTimeout
    Assert-Equal $expectedIdleTimeoutTimespan $idleTimeout 'App pool idle timeout not set correctly'
}

function Assert-Identity($expectedUsername, $expectedPassword)
{
    $actualUserName = Invoke-AppCmd list apppool $appPoolName /text:processModel.username
    Assert-Equal $expectedUsername $actualUserName 'App pool username not set correctly'
    $actualPassword = Invoke-AppCmd list apppool $appPoolName /text:processModel.password
    Assert-Equal $expectedPassword $actualPassword 'App pool username not set correctly'
}

function Assert-AppPool32BitEnabled($expected32BitEnabled)
{
    $32BitEnabled = Invoke-AppCmd list apppool $appPoolName /text:enable32BitAppOnWin64
    Assert-Equal ([string]$expected32BitEnabled) $32BitEnabled '32-bit apps enabled flag.'
}