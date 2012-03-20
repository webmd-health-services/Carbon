
Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force

# Only administratos can update trusted hosts.
if( Test-AdminPrivileges )
{
    $originalTrustedHosts = $null

    function Setup
    {
        $originalTrustedHosts = @( Get-TrustedHosts )
        Set-TrustedHosts
    }

    function TearDown
    {
        Set-TrustedHosts -Entries $originalTrustedHosts
    }

    function Test-ShouldAddNewHost
    {
        Add-TrustedHosts -Entries example.com
        $trustedHosts = @( Get-TrustedHosts )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal ($originalTrustedHosts.Count + 1) $trustedHosts.Count
    }

    function Test-ShouldAddMultipleHosts
    {
        Add-TrustedHosts -Entries example.com,webmd.com
        $trustedHosts = Get-TrustedHosts
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-True ($trustedHosts -contains 'webmd.com')
        Assert-Equal ($originalTrustedHosts.Count + 2) $trustedHosts.Count
    }

    function Test-ShouldNotDuplicateEntries
    {
        Add-TrustedHosts -Entries example.com
        Add-TrustedHosts -Entries example.com
        $trustedHosts = @( Get-TrustedHosts )
        Assert-True ($trustedHosts -contains 'example.com')
        Assert-Equal ($originalTrustedHosts.Count + 1) $trustedHosts.Count
    }
    
    function Test-ShouldSupportWhatIf
    {
        Add-TrustedHosts -Entries example.com -WhatIf
        $trustedHosts = @( Get-TrustedHosts )
        Assert-True ($trustedHosts -notcontains 'example.com')
        Assert-Equal $originalTrustedHosts.Count $trustedHosts.Count
        
    }
}