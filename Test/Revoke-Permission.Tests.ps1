
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
        Grant-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl'
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'when user has multiple access control entries on an item' {
        Grant-Permission -Path $script:testDirPath -Identity $credential.UserName -Permission 'Read'
        $perm = Get-Permission -Path $script:testDirPath -Identity $credential.UserName
        Mock -CommandName 'Get-Permission' -ModuleName 'Carbon' -MockWith { $perm ; $perm }.GetNewClosure()
        $Global:Error.Clear()
        Revoke-Permission -Path $script:testDirPath -Identity $credential.UserName
        $Global:Error | Should -BeNullOrEmpty
        Carbon\Get-Permission -Path $script:testDirPath -Identity $credential.UserName | Should -BeNullOrEmpty
    }

    It 'should revoke permission' {
        Revoke-Permission -Path $script:testDirPath -Identity $user
        $Global:Error.Count | Should -Be 0
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl') | Should -BeFalse
    }

    It 'should not revoke inherited permissions' {
        Get-Permission -Path $script:testDirPath -Inherited |
            Where-Object { $_.IdentityReference -notlike ('*{0}*' -f $user) } |
            ForEach-Object {
                $result = Revoke-Permission -Path $script:testDirPath -Identity $_.IdentityReference
                $Global:Error.Count | Should -Be 0
                $result | Should -BeNullOrEmpty
                (Test-Permission -Identity $_.IdentityReference -Path $script:testDirPath -Inherited -Permission $_.FileSystemRights) | Should -BeTrue
            }
    }

    It 'should handle revoking non existent permission' {
        Revoke-Permission -Path $script:testDirPath -Identity $user
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl') | Should -BeFalse
        Revoke-Permission -Path $script:testDirPath -Identity $user
        $Global:Error.Count | Should -Be 0
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl') | Should -BeFalse
    }

    It 'should resolve relative path' {
        Push-Location -Path (Split-Path -Parent -Path $script:testDirPath)
        try
        {
            Revoke-Permission -Path ('.\{0}' -f (Split-Path -Leaf -Path $script:testDirPath)) -Identity $user
            (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl') | Should -BeFalse
        }
        finally
        {
            Pop-Location
        }
    }

    It 'should support what if' {
        Revoke-Permission -Path $script:testDirPath -Identity $user -WhatIf
        (Test-Permission -Path $script:testDirPath -Identity $user -Permission 'FullControl') | Should -BeTrue
    }

    It 'should revoke permission on registry' {
        $regKey = 'hkcu:\TestRevokePermissions'
        New-Item $regKey

        try
        {
            Grant-Permission -Identity $user -Permission 'ReadKey' -Path $regKey
            $result = Revoke-Permission -Path $regKey -Identity $user
            $result | Should -BeNullOrEmpty
            (Test-Permission -Path $regKey -Identity $user -Permission 'ReadKey') | Should -BeFalse
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
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl'
            (Get-Permission -Path $certPath -Identity $user) | Should -Not -BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user
            $Global:Error.Count | Should -Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should -BeNullOrEmpty
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
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -WhatIf
            $Global:Error.Count | Should -Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should -BeNullOrEmpty
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
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl'
            (Get-Permission -Path $certPath -Identity $user) | Should -Not -BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user -WhatIf
            $Global:Error.Count | Should -Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should -Not -BeNullOrEmpty
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
            Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl'
            Get-Permission -Path $certPath -Identity $user | Should -Not -BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user
            $Global:Error.Count | Should -Be 0
            Get-Permission -Path $certPath -Identity $user | Should -BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }

}
