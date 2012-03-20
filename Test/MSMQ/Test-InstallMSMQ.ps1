
# These tests should only run if MSMQ is not installed and we're on Windows 7/2008 R2
if( -not (Get-Service -Name MSMQ -ErrorAction SilentlyContinue) -and (Get-WmiObject Win32_OperatingSystem).Version -like '6.1*' )
{
    $msmqPath = Join-Path $env:SystemRoot 'system32\mqsvc.exe'
    $msmqServiceName = "MSMQ"

    function Setup
    {
        Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    }

    function TearDown
    {
        if( (Get-MSMQService) )
        {
            Stop-Service $msmqServiceName -Force
            Uninstall-WindowsFeatures -Components MSMQ-ADIntegration,MSMQ-HTTP,MSMQ-Server,MSMQ-Container
        }
        Remove-Module Carbon
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
        Assert-True (Test-WindowsFeatures MSMQ-ADIntegration)
        Assert-True (Test-WindowsFeatures MSMQ-HTTP)
        
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
        Assert-True (Test-WindowsFeatures MSMQ-Container)
        Assert-True (Test-WindowsFeatures MSMQ-Server)
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