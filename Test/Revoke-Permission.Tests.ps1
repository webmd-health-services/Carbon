
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    $script:testDirPath = ''
    $script:testNum = 0
    $user = 'CarbonGrantPerms'
    $containerPath = $null
    $privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve
    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $credential = New-CCredential -UserName $user -Password 'a1b2c3d4!'
    Install-CUser -Credential $credential -Description 'User for Carbon Grant-Permission tests.'
}

Describe 'Revoke-Permission' {
    BeforeEach {
        $Global:Error.Clear()
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDirPath -ItemType 'Directory'
        Grant-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl' -NoWarn
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'when user has multiple access control entries on an item' {
        Grant-Permission -Path $script:testDirPath -Identity $credential.UserName -Permission 'Read' -NoWarn
        $perm = Get-Permission -Path $script:testDirPath -Identity $credential.UserName -NoWarn
        Mock -CommandName 'Get-Permission' -ModuleName 'Carbon' -MockWith { $perm ; $perm }.GetNewClosure()
        $Global:Error.Clear()
        Revoke-Permission -Path $script:testDirPath -Identity $credential.UserName -NoWarn
        $Global:Error | Should -BeNullOrEmpty
        Carbon\Get-Permission -Path $script:testDirPath -Identity $credential.UserName -NoWarn | Should -BeNullOrEmpty
    }

    It 'should revoke permission' {
        Revoke-Permission -Path $script:testDirPath -Identity $user -NoWarn
        $Global:Error.Count | Should -Be 0
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl' -NoWarn) | Should -BeFalse
    }

    It 'should not revoke inherited permissions' {
        Get-Permission -Path $script:testDirPath -Inherited -NoWarn |
            Where-Object { $_.IdentityReference -notlike ('*{0}*' -f $user) } |
            ForEach-Object {
                $result = Revoke-Permission -Path $script:testDirPath -Identity $_.IdentityReference -NoWarn
                $Global:Error.Count | Should -Be 0
                $result | Should -BeNullOrEmpty
                Test-Permission -Identity $_.IdentityReference -Path $script:testDirPath -Inherited -Permission $_.FileSystemRights -NoWarn |
                    Should -BeTrue
            }
    }

    It 'should handle revoking non existent permission' {
        Revoke-Permission -Path $script:testDirPath -Identity $user -NoWarn
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl' -NoWarn) | Should -BeFalse
        Revoke-Permission -Path $script:testDirPath -Identity $user
        $Global:Error.Count | Should -Be 0
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl' -NoWarn) | Should -BeFalse
    }

    It 'should resolve relative path' {
        Push-Location -Path (Split-Path -Parent -Path $script:testDirPath)
        try
        {
            Revoke-Permission -Path ('.\{0}' -f (Split-Path -Leaf -Path $script:testDirPath)) -Identity $user -NoWarn
            Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl' -NoWarn |
                Should -BeFalse
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should support what if' {
        Revoke-Permission -Path $script:testDirPath -Identity $user -NoWarn -WhatIf
        Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl' -NoWarn | Should -BeTrue
    }

    It 'should revoke permission on registry' {
        $regKey = 'hkcu:\TestRevokePermissions'
        New-Item $regKey

        try
        {
            Grant-Permission -Identity $user -Permission 'ReadKey' -Path $regKey -NoWarn
            $result = Revoke-Permission -Path $regKey -Identity $user -NoWarn
            $result | Should -BeNullOrEmpty
            Test-Permission -Path $regKey -Identity $user -Permission 'ReadKey' -NoWarn | Should -BeFalse
        }
        finally
        {
            Remove-Item $regKey
        }
    }

    It 'should revoke local machine private key permissions' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -NoWarn
            (Get-Permission -Path $certPath -Identity $user -NoWarn) | Should -Not -BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user
            $Global:Error.Count | Should -Be 0
            (Get-Permission -Path $certPath -Identity $user -NoWarn) | Should -BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }

    It 'should revoke current user private key permissions' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -NoWarn -WhatIf
            $Global:Error.Count | Should -Be 0
            (Get-Permission -Path $certPath -Identity $user -NoWarn) | Should -BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My -NoWarn
        }
    }

    It 'should support what if when revoking private key permissions' {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -NoWarn
            (Get-Permission -Path $certPath -Identity $user -NoWarn) | Should -Not -BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user -NoWarn -WhatIf
            $Global:Error.Count | Should -Be 0
            (Get-Permission -Path $certPath -Identity $user -NoWarn) | Should -Not -BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }

    It 'revokes permission on cng certificate' {
        $cngCertPath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonRsaCng.pfx' -Resolve
        $cert = Install-Certificate -Path $cngCertPath -StoreLocation LocalMachine -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -NoWarn
            Get-Permission -Path $certPath -Identity $user -NoWarn | Should -Not -BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user -NoWarn
            $Global:Error.Count | Should -Be 0
            Get-Permission -Path $certPath -Identity $user -NoWarn | Should -BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }

}
