
$siteName = 'UnlockIisConfigSection'
$windowsAuthWasLocked = $false

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    Install-IisWebsite -Name $siteName -Path $TestDir
    $windowsAuthWasLocked = -not (Get-WindowsAuthenticationUnlocked)
    Invoke-AppCmd lock config /section:windowsAuthentication
    
}

function TearDown
{
    # Put things back the way we found them.
    if( $windowsAuthWasLocked )
    {
        Invoke-AppCmd lock config /section:windowsAuthentication
    }
    
    $webConfigPath = Join-Path $TestDir web.config
    if( Test-Path -Path $webConfigPath )
    {
        Remove-Item $webConfigPath
    }

    Remove-IisWebsite $siteName
    Remove-Module Carbon
}

function Test-ShouldUnlockConfigSection
{
    Unlock-IisConfigSection -Name windowsAuthentication
    Assert-True (Get-WindowsAuthenticationUnlocked)
}

function Test-ShouldSupportWhatIf
{
    Unlock-IisConfigSection -Name windowsAuthentication -WhatIf
    Assert-False (Get-WindowsAuthenticationUnlocked)
}

function Get-WindowsAuthenticationUnlocked
{
    $result = Invoke-AppCmd set config $SiteName /section:windowsAuthentication /enabled:true -ErrorAction SilentlyContinue
    return ( $LastExitCode -eq 0 )
}