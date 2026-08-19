
#Requires -Version 5.1
Set-StrictMode -VErsion 'Latest'

BeforeAll {
    Set-StrictMode -VErsion 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)
    $script:user = $null
    $script:url = 'http://test-gethttpurlacl:10939/'

    function Assert-TestUrl
    {
        param(
            [Carbon.Security.HttpUrlSecurity[]]
            $Acls
        )

        $Global:Error.Count | Should -Be 0

        $Acls | Should -Not -BeNullOrEmpty
        $Acls.Count | Should -Be 1

        $acl = $Acls[0]
        $acl.Access.Count | Should -Be 1
        $rule = $acl.Access[0]
        $rule.IdentityReference | Should -Be ('{0}\{1}' -f $env:COMPUTERNAME,$CarbonTestUser.UserName)
    }

    function GivenUser
    {
        param(
            $UserName,
            $Description
        )

        $script:user = Install-CUser -Credential (New-CCredential -UserName $UserName -Password 'Password1') -Description $Description -PassThru
    }

    function GivenUrlAcl
    {
        param(
            $Url,
            $UserName
        )

        netsh http add urlacl ('url={0}' -f $Url) ('user={0}\{1}' -f $env:COMPUTERNAME,$UserName) | Write-Debug
    }

}

Describe 'Get-CHttpUrlAcl' {
    BeforeEach {
        $Global:Error.Clear()
        netsh http add urlacl ('url={0}' -f $script:url)('user={0}\{1}' -f $env:COMPUTERNAME,$CarbonTestUser.UserName) | Write-Debug
    }

    AfterEach {
        netsh http delete urlacl ('url={0}' -f $script:url)
    }

    It 'should get all url acls' {
        [Carbon.Security.HttpUrlSecurity[]]$acls = Get-CHttpUrlAcl
        $acls | Should -Not -BeNullOrEmpty
        $urlacl = netsh http show urlacl
        $urlacl = $urlacl -join [Environment]::NewLine

        foreach( $acl in $acls )
        {
            $header = '' -f $acl.Url

            if( $acl.Access.Count -eq 1 )
            {
                # The ACL has a SID for a dead/deleted identity. Skip those.
                if( $acl.Access[0].IdentityReference -is [Security.Principal.SecurityIdentifier] )
                {
                    continue
                }

                $rule = $acl.Access[0]
                $identity = $rule.IdentityReference.ToString()
                if( $identity -eq 'Everyone' )
                {
                    $identity = '\Everyone'
                }

                $listen = 'No'
                if( $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::Listen -or $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate )
                {
                    $listen = 'Yes'
                }

                $delegate = 'No'
                if( $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::Delegate -or $rule.HttpUrlAccessRights -eq [Carbon.Security.HttpUrlAccessRights]::ListenAndDelegate )
                {
                    $delegate = 'Yes'
                }

                $regex = 'Reserved\ URL\s+:\s+{0}\s+User:\s+{1}\s+Listen:\s+{2}\s+Delegate:\s+{3}' -f [regex]::Escape($acl.Url),[regex]::escape($identity),[regex]::Escape($listen),[regex]::Escape($delegate)
                $urlacl | Should -Match $regex

            }
        }
    }

    It 'should get specific url' {
        [Carbon.Security.HttpUrlSecurity[]]$acls = Get-CHttpUrlAcl -LiteralUrl $script:url
        Assert-TestUrl $acls
    }


    It 'should ignore wildcards with literal url parameter' {
        [Carbon.Security.HttpUrlSecurity[]]$acls = Get-CHttpUrlAcl -LiteralUrl 'http://*:10939/' -ErrorAction SilentlyContinue
        $acls | Should -BeNullOrEmpty
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
    }

    It 'should find with wildcard' {
        [Carbon.Security.HttpUrlSecurity[]]$acls = Get-CHttpUrlAcl -Url 'http://*:10939/'
        Assert-TestUrl $acls
    }

    It 'should write error if literal url not found' {
        $acl = Get-CHttpUrlAcl -LiteralUrl 'fubar' -ErrorAction SilentlyContinue
        $acl | Should -BeNullOrEmpty
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
    }

    It 'should fail if url with no wildcards not found' {
        $acl = Get-CHttpUrlAcl -Url 'fubar' -ErrorAction SilentlyContinue
        $acl | Should -BeNullOrEmpty
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'not found'
    }

    It 'should not fail if url with wildcards not found' {
        $acl = Get-CHttpUrlAcl -Url 'fubar*'
        $acl | Should -BeNullOrEmpty
        $Global:Error.Count | Should -Be 0
    }

}

Describe 'Get-CHttpUrlAcl' {
    BeforeEach {
        $script:user = $null
    }

    It 'returns ACL for non-existent identity' {
        $url = 'http://+:8999/'
        netsh http delete urlacl ('url={0}' -f $url)
        $existingUrlAcls = Get-CHttpUrlAcl
        GivenUser 'cgethttpurlacl' 'Carbon test user for Get-CHttpUrlAcl'
        GivenUrlAcl $url 'cgethttpurlacl'
        Uninstall-CUser 'cgethttpurlacl'
        $urlAclsNow = Get-CHttpUrlAcl
        $urlAclsNow | Should -HaveCount (($existingUrlAcls | Measure-Object).Count + 1)
        $badSidAcl = $urlAclsNow | Where-Object { $_.Url -eq $url }
        $badSidAcl | Should -Not -BeNullOrEmpty
        $badSidAcl.Access | Where-Object { $_.IdentityReference.Value -eq $script:user.Sid.Value } | Should -Not -BeNullOrEmpty
    }
}
