
$CategoryName = 'Carbon-PerformanceCounters-UninstallCategory'

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    [Diagnostics.PerformanceCounterCategory]::Create( $CategoryName, '', (New-Object Diagnostics.CounterCreationDataCollection) )
    Assert-True (Test-PerformanceCounterCategory -CAtegoryName $CAtegoryName) 
}

function TearDown
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName
    Assert-False (Test-PerformanceCounterCategory -CAtegoryName $CAtegoryName) 
}

function Test-ShouldSupportWhatIf
{
    Uninstall-PerformanceCounterCategory -CategoryName $CategoryName -WhatIf
    Assert-True (Test-PerformanceCounterCategory -CategoryName $CategoryName)
}


