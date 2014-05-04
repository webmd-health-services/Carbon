# Copyright 2012 Aaron Jensen
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$appPoolName = 'CarbonInstallIisAppPool'
$username = 'CarbonInstallIisAppP'
$password = '!QAZ2wsx'

function Start-TestFixture
{
    & (Join-Path -Path $PSScriptRoot '..\..\Carbon\Import-Carbon.ps1' -Resolve)
}

function Start-Test
{
    Remove-AppPool
    Install-User -Username $username -Password $password -Description 'User for testing Carbon''s Install-IisAppPool function.'
    Revoke-Privilege -Identity $username -Privilege SeBatchLogonRight
}

function Stop-Test
{
    Remove-AppPool
    Uninstall-User -Username $username
}

function Remove-AppPool
{
    Uninstall-IisAppPool -Name $appPoolName
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
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-NotNull $appPool
    Assert-Equal ([Microsoft.Web.Administration.ObjectState]::Started) $appPool.state
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
    Install-IisAppPool -Name $appPoolName -UserName $username -Password $password
    Assert-AppPoolExists
    Assert-Identity $username $password
    Assert-IdentityType 'SpecificUser'
    Assert-Contains (Get-Privilege $username) 'SeBatchLogonRight' 'custom user not granted SeBatchLogonRight'
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
    $exists = Test-IisAppPool -Name $appPoolname
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
    $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
    Install-IisAppPool -Name $appPoolName -Username $username -Password $securePassword
    Assert-Identity $username $password
}

function Test-ShouldConvert32BitAppPoolto64Bit
{
    Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService -Enable32BitApps
    Assert-AppPool32BitEnabled $true
    Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
    Assert-AppPool32BitEnabled $false    
}

function Test-ShouldSwitchToAppPoolIdentityIfServiceAccountNotGiven
{
    Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
    Assert-IdentityType 'NetworkService'
    Install-IisAppPool -Name $appPoolName
    Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
}

function Test-ShouldStartStoppedAppPool
{
    Install-IisAppPool -Name $appPoolName 
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-NotNull $appPool
    if( $appPool.state -ne [Microsoft.Web.Administration.ObjectState]::Stopped )
    { 
        Start-Sleep -Seconds 1
        $appPool.Stop()
    }
    
    Install-IisAppPool -Name $appPoolName
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-Equal ([Microsoft.Web.Administration.ObjectState]::Started) $appPool.state
}

function Test-ShouldFailIfIdentityDoesNotExist
{
    $error.Clear()
    Install-IisAppPool -Name $appPoolName -Username 'IDoNotExist' -Password 'blahblah' -ErrorAction SilentlyContinue
    Assert-True (Test-IisAppPool -Name $appPoolName)
    Assert-True ($error.Count -ge 2)
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
