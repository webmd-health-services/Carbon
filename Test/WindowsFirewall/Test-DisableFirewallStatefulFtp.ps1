
$alreadyEnabled = $false

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    
    $alreadyEnabled = Test-FirewallStatefulFtp
    
    if( -not $alreadyEnabled )
    {
        Enable-FirewallStatefulFtp
    }
}

function TearDown
{
    if( $alreadyEnabled )
    {
        Enable-FirewallStatefulFtp
    }
    else
    {
        Disable-FirewallStatefulFtp
    }
}

function Test-ShouldDisableStatefulFtp
{
    Disable-FirewallStatefulFtp
    $enabled = Test-FirewallStatefulFtp
    Assert-False $enabled 'StatefulFtp not enabled on firewall.'
}

function Test-ShouldSupportWhatIf
{
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFTP not enabled'
    Disable-FirewallStatefulFtp -WhatIf
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFTP disable with -WhatIf parameter given.'
}