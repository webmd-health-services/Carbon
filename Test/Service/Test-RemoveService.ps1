
$serviceBaseName = 'CarbonGrantControlServiceTest'
$serviceName = $serviceBaseName
$servicePath = Join-Path $TestDir NoOpService.exe

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    $serviceName = $serviceBaseName + ([Guid]::NewGuid().ToString())
    Install-Service -Name $serviceName -Path $servicePath
}

function TearDown
{
    if( (Get-Service $serviceName -ErrorAction SilentlyContinue) )
    {
        Stop-Service $serviceName
        & C:\Windows\system32\sc.exe delete $serviceName
    }
    Remove-Module Carbon
}

function Test-ShouldRemoveService
{
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
    Remove-Service -Name $serviceName
    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
    Assert-Null $service
}

function Test-ShouldNotRemoveNonExistentService
{
    $error.Clear()
    Remove-Service -Name "IDoNotExist"
    Assert-Null $error
}

function Test-ShouldSupportWhatIf
{
    Remove-Service -Name $serviceName -WhatIf
    $service = Get-Service -Name $serviceName
    Assert-NotNull $service
}