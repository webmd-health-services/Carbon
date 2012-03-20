
$alreadyEnabled = $false

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    
    $alreadyEnabled = Test-FirewallStatefulFtp
    
    if( $alreadyEnabled )
    {
        Disable-FirewallStatefulFtp
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

function Test-ShouldEnableStatefulFtp
{
    Enable-FirewallStatefulFtp
    $enabled = Test-FirewallStatefulFtp
    Assert-True $enabled 'StatefulFtp not enabled on firewall.'
}

function Test-ShouldSupportWhatIf
{
    Enable-FirewallStatefulFtp -WhatIf
    $enabled = Test-FirewallStatefulFtp
    Assert-False $enabled 'StatefulFTP enabled with -WhatIf parameter given.'
}