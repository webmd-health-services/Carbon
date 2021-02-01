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
$password = '!QAZ2wsx8fk3'

& (Join-Path -Path $PSScriptRoot 'Initialize-CarbonTest.ps1' -Resolve)

Install-User -Credential (New-Credential -Username $username -Password $password) -Description 'User for testing Carbon''s Install-IisAppPool function.'

function Assert-AppPoolExists
{
    $exists = Test-IisAppPool -Name $appPoolname
    $exists | Should Be $true
}
    
function Assert-ManagedRuntimeVersion($Version)
{
    $apppool = Get-IisAppPool -Name $appPoolName
    $apppool.ManagedRuntimeVersion | Should Be $Version
}
    
function Assert-ManagedPipelineMode($expectedMode)
{
    $apppool = Get-IisAppPool -Name $appPoolName
    $apppool.ManagedPipelineMode | Should Be $expectedMode
}
    
function Assert-IdentityType($expectedIdentityType)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $appPool.ProcessModel.IdentityType | Should Be $expectedIdentityType
}
    
function Assert-IdleTimeout($expectedIdleTimeout)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $expectedIdleTimeoutTimespan = New-TimeSpan -minutes $expectedIdleTimeout
    $appPool.ProcessModel.IdleTimeout | Should Be $expectedIdleTimeoutTimespan
}
    
function Assert-Identity($expectedUsername, $expectedPassword)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $appPool.ProcessModel.UserName | Should Be $expectedUsername
    $appPool.ProcessModel.Password | Should Be $expectedPassword
}
    
function Assert-AppPool32BitEnabled([bool]$expected32BitEnabled)
{
    $appPool = Get-IisAppPool -Name $appPoolName
    $appPool.Enable32BitAppOnWin64 | Should Be $expected32BitEnabled
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
    
    $AppPool.ManagedRuntimeVersion | Should Be $ManangedRuntimeVersion
    $pipelineMode = 'Integrated'
    if( $ClassicPipelineMode )
    {
        $pipelineMode = 'Classic'
    }
    $AppPool.ManagedPipelineMode | Should Be $pipelineMode
    $AppPool.ProcessModel.IdentityType | Should Be $IdentityType
    $AppPool.Enable32BitAppOnWin64 | Should Be ([bool]$Enable32Bit)
    $AppPool.ProcessModel.IdleTimeout | Should Be $IdleTimeout
    
    $MAX_TRIES = 20
    for ( $idx = 0; $idx -lt $MAX_TRIES; ++$idx )
    {
        $AppPool = Get-IisAppPool -Name $appPoolName
        $AppPool | Should Not BeNullOrEmpty
        if( $AppPool.State )
        {
            $AppPool.State | Should Be ([Microsoft.Web.Administration.ObjectState]::Started)
            break
        }
        Start-Sleep -Milliseconds 1000
    }
}

function Start-Test
{
    Uninstall-IisAppPool -Name $appPoolName
    Revoke-Privilege -Identity $username -Privilege SeBatchLogonRight
}
    
Describe 'Install-IisAppPool when running no manage code' {
    Start-Test

    Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion ''
    It 'should set managed runtime to nothing' {
        Assert-ManagedRuntimeVersion -Version ''
    }
}
    
Describe 'Install-IisAppPool' {
    BeforeEach {
        Start-Test
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
    
    It 'should create new app pool' {
        $result = Install-IisAppPool -Name $appPoolName -PassThru
        $result | Should Not BeNullOrEmpty
        Assert-AppPool $result
    }
    
    It 'should create new app pool but not r eturn object' {
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
        $appPool = Get-IisAppPool -Name $appPoolName
        $appPool | Should Not BeNullOrEmpty
        Assert-AppPool $appPool
        
    }
    
    It 'should set managed runtime version' {
        $result = Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0'
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v2.0'
    }
    
    It 'should set managed pipeline mode' {
        $result = Install-IisAppPool -Name $appPoolName -ClassicPipelineMode
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedPipelineMode 'Classic'
    }
    
    It 'should set identity as service account' {
        $result = Install-IisAppPool -Name $appPoolName -ServiceAccount 'NetworkService'
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-IdentityType 'NetworkService'
    }
    
    It 'should set identity as specific user' {
        $warnings = @()
        $result = Install-CIisAppPool -Name $appPoolName -UserName $username -Password $password -WarningVariable 'warnings'
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Identity $username $password
        Assert-IdentityType 'SpecificUser'
        Get-Privilege $username | Where-Object { $_ -eq 'SeBatchLogonRight' } | Should Not BeNullOrEmpty
        $warnings.Count | Should Be 1
        ($warnings[0] -like '*obsolete*') | Should Be $true
    }
    
    It 'should set identity with credential' {
        $credential = New-Credential -UserName $username -Password $password
        $credential | Should Not BeNullOrEmpty
        $result = Install-IisAppPool -Name $appPoolName -Credential $credential
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Identity $credential.UserName $credential.GetNetworkCredential().Password
        Assert-IdentityType 'Specificuser'
        Get-Privilege $username | Where-Object { $_ -eq 'SeBatchLogonRight' } | Should Not BeNullOrEmpty
    }
    
    It 'should set idle timeout' {
        $result = Install-IisAppPool -Name $appPoolName -IdleTimeout 55
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-Idletimeout 55
    }
    
    It 'should enable32bit apps' {
        $result = Install-IisAppPool -Name $appPoolName -Enable32BitApps
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-AppPool32BitEnabled $true
    }
    
    It 'should handle app pool that exists' {
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
    }
    
    It 'should change settings on existing app pool' {
        $result = Install-IisAppPool -Name $appPoolName
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v4.0'
        Assert-ManagedPipelineMode 'Integrated'
        Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
    
        Assert-AppPool32BitEnabled $false
    
        $result = Install-IisAppPool -Name $appPoolName -ManagedRuntimeVersion 'v2.0' -ClassicPipeline -ServiceAccount 'LocalSystem' -Enable32BitApps
        $result | Should BeNullOrEmpty
        Assert-AppPoolExists
        Assert-ManagedRuntimeVersion 'v2.0'
        Assert-ManagedPipelineMode 'Classic'
        Assert-IdentityType 'LocalSystem'
        Assert-AppPool32BitEnabled $true
    
    }
    
    It 'should accept secure string for app pool password' {
        $securePassword = ConvertTo-SecureString -String $password -AsPlainText -Force
        Install-IisAppPool -Name $appPoolName -Username $username -Password $securePassword
        Assert-Identity $username $password
    }
    
    It 'should convert32 bit app poolto64 bit' {
        Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService -Enable32BitApps
        Assert-AppPool32BitEnabled $true
        Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
        Assert-AppPool32BitEnabled $false    
    }
    
    It 'should switch to app pool identity if service account not given' {
        Install-IisAppPool -Name $appPoolName -ServiceAccount NetworkService
        Assert-IdentityType 'NetworkService'
        Install-IisAppPool -Name $appPoolName
        Assert-IdentityType (Get-IISDefaultAppPoolIdentity)
    }
    
    It 'should start stopped app pool' {
        Install-IisAppPool -Name $appPoolName 
        $appPool = Get-IisAppPool -Name $appPoolName
        $appPool | Should Not BeNullOrEmpty
        if( $appPool.state -ne [Microsoft.Web.Administration.ObjectState]::Stopped )
        { 
            Start-Sleep -Seconds 1
            $appPool.Stop()
        }
        
        Install-IisAppPool -Name $appPoolName
        $appPool = Get-IisAppPool -Name $appPoolName
        $appPool.state | Should Be ([Microsoft.Web.Administration.ObjectState]::Started)
    }
    
    It 'should fail if identity does not exist' {
        $error.Clear()
        Install-IisAppPool -Name $appPoolName -Username 'IDoNotExist' -Password 'blahblah' -ErrorAction SilentlyContinue
        (Test-IisAppPool -Name $appPoolName) | Should Be $true
        ($error.Count -ge 2) | Should Be $true
    }
    
    
}

Start-Test
