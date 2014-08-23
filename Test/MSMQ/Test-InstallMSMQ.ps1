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

# These tests should only run if MSMQ is not installed and we're on Windows 7/2008 R2
if( -not (Get-Service -Name MSMQ -ErrorAction SilentlyContinue) -and (Get-WmiObject Win32_OperatingSystem).Version -like '6.1*' )
{
    $msmqPath = Join-Path $env:SystemRoot 'system32\mqsvc.exe'
    $msmqServiceName = "MSMQ"

    function Start-TestFixture
    {
        & (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    }

    function Stop-Test
    {
        if( (Get-MSMQService) )
        {
            Stop-Service $msmqServiceName -Force
            Uninstall-WindowsFeature -Name MSMQ-ADIntegration,MSMQ-HTTP,MSMQ-Server,MSMQ-Container
        }
    }

    function Test-ShouldInstallMSMQ
    {
        Assert-MSMQNotInstalled
        Install-MSMQ
        Assert-MSMQInstalled
    }

    function Test-ShouldInstallAdditionalMSMQComponents
    {
        Stop-Service -Name MSDTC
        (Get-Service -Name MSDTC).WaitForStatus( 'Stopped' )
        Set-Service -Name MSDTC -StartupType Manual
        
        Assert-MSMQNotInstalled
        Install-MSMQ -HttpSupport -ActiveDirectoryIntegration -DTC
        Assert-MSMQInstalled
        Assert-True (Test-WindowsFeatures MSMQ-ADIntegration -Installed)
        Assert-True (Test-WindowsFeatures MSMQ-HTTP -Installed)
        
        $dtcSvc = Get-Service -Name MSDTC
        Assert-Equal 'Automatic' $dtcSvc.StartMode
        Assert-Equal 'Running' $dtcSvc.Status
    }

    function Test-ShouldSupportWhatIf
    {
        Assert-MSMQNotInstalled
        Install-MSMQ -WhatIf
        Assert-MSMQNotInstalled
    }

    function Assert-MSMQInstalled
    {
        Assert-FileExists $msmqPath
        Assert-NotNull (Get-MSMQService)
        Assert-True (Test-WindowsFeatures MSMQ-Container -Installed)
        Assert-True (Test-WindowsFeatures MSMQ-Server -Installed)
    }

    function Assert-MSMQNotInstalled
    {
        Assert-FileDoesNotExist $msmqPath
        Assert-Null (Get-MSMQService)
    }

    function Get-MSMQService
    {
        Get-Service $msmqServiceName -ErrorAction SilentlyContinue
    }
}
else
{
    Write-Warning "Install-MSMQ tests not run because MSMQ is installed."
}
