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
    & (Join-Path -Path $PSScriptRoot '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    Remove-AppPool
    Install-User -Credential (New-Credential -Username $username -Password $password) -Description 'User for testing Carbon''s Install-IisAppPool function.'
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
    $result = Install-IisAppPool -Name $appPoolName -PassThru
    Assert-NotNull $result
    Assert-AppPool $result
}

function Test-ShouldCreateNewAppPoolButNotREturnObject
{
    $result = Install-IisAppPool -Name $appPoolName
    Assert-Null $result
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-NotNull $appPool
    Assert-AppPool $appPool
    
}

function Test-ShouldSetManagedRuntimeVersion
{
    $result = Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0'
    Assert-Null $result
    Assert-AppPoolExists
    Assert-ManagedRuntimeVersion 'v2.0'
}

function Test-ShouldSetManagedPipelineMode
{
    $result = Install-IisAppPool -Name $appPoolName -ClassicPipelineMode
    Assert-Null $result
    Assert-AppPoolExists
    Assert-ManagedPipelineMode 'Classic'
}

function Test-ShouldSetIdentityAsServiceAccount
{
    $result = Install-IisAppPool -Name $appPoolName -ServiceAccount 'NetworkService'
    Assert-Null $result
    Assert-AppPoolExists
    Assert-IdentityType 'NetworkService'
}

function Test-ShouldSetIdentityAsSpecificUser
{
    $warnings = @()
    $result = Install-IisAppPool -Name $appPoolName -UserName $username -Password $password -WarningVariable 'warnings'
    Assert-Null $result
    Assert-AppPoolExists
    Assert-Identity $username $password
    Assert-IdentityType 'SpecificUser'
    Assert-Contains (Get-Privilege $username) 'SeBatchLogonRight' 'custom user not granted SeBatchLogonRight'
    Assert-Equal 1 $warnings.Count
    Assert-Like $warnings[0] '*obsolete*'
}

function Test-ShouldSetIdentityWithCredential
{
    $credential = New-Credential -UserName $username -Password $password
    Assert-NotNull $credential
    $result = Install-IisAppPool -Name $appPoolName -Credential $credential
    Assert-Null $result
    Assert-AppPoolExists
    Assert-Identity $credential.UserName $credential.GetNetworkCredential().Password
    Assert-IdentityType 'Specificuser'
    Assert-Contains (Get-Privilege $username) 'SeBatchLogonRight' 'custom user not granted SeBatchLogonRight'
}

function Test-ShouldSetIdleTimeout
{
    $result = Install-IisAppPool -Name $appPoolName -IdleTimeout 55
    Assert-Null $result
    Assert-AppPoolExists
    Assert-Idletimeout 55
}

function Test-ShouldEnable32bitApps
{
    $result = Install-IisAppPool -Name $appPoolName -Enable32BitApps
    Assert-Null $result
    Assert-AppPoolExists
    Assert-AppPool32BitEnabled $true
}

function Test-ShouldHandleAppPoolThatExists
{
    $result = Install-IisAppPool -Name $appPoolName
    Assert-Null $result
    $result = Install-IisAppPool -Name $appPoolName
    Assert-Null $result
}

function Assert-AppPoolExists
{
    $exists = Test-IisAppPool -Name $appPoolname
    Assert-True $exists "App pool '$appPoolName' not created."
}

function Test-ShouldChangeSettingsOnExistingAppPool
{
    $result = Install-IisAppPool -Name $appPoolName
    Assert-Null $result
    Assert-AppPoolExists
    Assert-ManagedRuntimeVersion 'v4.0'
    Assert-ManagedPipelineMode 'Integrated'
    Assert-IdentityType (Get-IISDefaultAppPoolIdentity)

    Assert-AppPool32BitEnabled $false

    $result = Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0' -ClassicPipeline -ServiceAccount 'LocalSystem' -Enable32BitApps
    Assert-Null $result
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

function Assert-ManagedRuntimeVersion($Version)
{
    $apppool = Get-IisAppPool -Name $appPoolName
    Assert-Equal $Version $apppool.ManagedRuntimeVersion "App pool's managed runtime not at correct version."
}

function Assert-ManagedPipelineMode($expectedMode)
{
    $apppool = Get-IisAppPool -Name $appPoolName
    Assert-Equal $expectedMode $apppool.ManagedPipelineMode "App pool's managed pipeline not in $expectedMode mode."
}

function Assert-IdentityType($expectedIdentityType)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-Equal $expectedIdentityType $appPool.ProcessModel.IdentityType 'App pool identity type not set correctly'
}

function Assert-IdleTimeout($expectedIdleTimeout)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $expectedIdleTimeoutTimespan = New-TimeSpan -minutes $expectedIdleTimeout
    Assert-Equal $expectedIdleTimeoutTimespan $appPool.ProcessModel.IdleTimeout 'App pool idle timeout not set correctly'
}

function Assert-Identity($expectedUsername, $expectedPassword)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-Equal $expectedUsername $appPool.ProcessModel.UserName 'App pool username not set correctly'
    Assert-Equal $expectedPassword $appPool.ProcessModel.Password 'App pool password not set correctly'
}

function Assert-AppPool32BitEnabled([bool]$expected32BitEnabled)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    Assert-Equal $expected32BitEnabled $appPool.Enable32BitAppOnWin64 '32-bit apps enabled flag.'
}

function Assert-AppPool
{
    param(
        [Parameter(Position=0)]
        $AppPool,

        $ManangedRuntimeVersion = 'v4.0',

        [Switch]
        $ClassicPipelineMode,

        $IdentityType = (Get-IISDefaultAppPoolIdentity),

        [Switch]
        $Enable32Bit,

        [TimeSpan]
        $IdleTimeout = (New-TimeSpan -Seconds 0)
    )

    Set-StrictMode -Version 'Latest'

    Assert-AppPoolExists

    if( -not $AppPool )
    {
        $AppPool = Get-IisAppPool -Name $appPoolName
    }

    Assert-Equal $ManangedRuntimeVersion $AppPool.ManagedRuntimeVersion
    $pipelineMode = 'Integrated'
    if( $ClassicPipelineMode )
    {
        $pipelineMode = 'Classic'
    }
    Assert-Equal $pipelineMode $AppPool.ManagedPipelineMode
    Assert-Equal $IdentityType $AppPool.ProcessModel.IdentityType
    Assert-Equal ([bool]$Enable32Bit) $AppPool.Enable32BitAppOnWin64
    Assert-Equal $IdleTimeout $AppPool.ProcessModel.IdleTimeout

    $MAX_TRIES = 20
    for ( $idx = 0; $idx -lt $MAX_TRIES; ++$idx )
    {
        $AppPool = Get-IisAppPool -Name $appPoolName
        Assert-NotNull $AppPool
        if( $AppPool.State )
        {
            Assert-Equal ([Microsoft.Web.Administration.ObjectState]::Started) $AppPool.State
            break
        }
        Start-Sleep -Milliseconds 1000
    }
}


