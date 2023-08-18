# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:identity = $CarbonTestUser.UserName
    $script:tempDir = New-CTempDirectory
    Install-CDirectory (Join-Path -path $script:tempDir -ChildPath 'Directory')
    New-Item (Join-Path -path $script:tempDir -ChildPath 'File') -ItemType File

    $script:privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve

    $script:dirPath = Join-Path -Path $script:tempDir -ChildPath 'Directory'
    $script:filePath = Join-Path -Path $script:dirPath -ChildPath 'File'
    New-Item -Path $script:filePath -ItemType File
    Grant-CPermission -Identity $script:identity -Permission ReadAndExecute -Path $script:dirPath -ApplyTo 'ChildLeaves'

    $script:tempKeyPath = 'hkcu:\Software\Carbon\Test'
    $script:keyPath = Join-Path -Path $script:tempKeyPath -ChildPath 'Test-CPermission'
    Install-CRegistryKey -Path $script:keyPath -NoWarn
    $script:childKeyPath = Join-Path -Path $script:keyPath -ChildPath 'ChildKey'
    Grant-CPermission -Identity $script:identity `
                      -Permission 'ReadKey','WriteKey' `
                      -Path $script:keyPath `
                      -ApplyTo 'ChildLeaves'

    $script:testDirPermArgs = @{
        Path = $script:dirPath;
        Identity = $script:identity;
    }


    $script:testFilePermArgs = @{
        Path = $script:filePath;
        Identity = $script:identity;
    }
}

AfterAll {
    Remove-Item -Path $script:tempDir -Recurse
    Remove-Item -Path $script:tempKeyPath -Recurse
}

Describe 'Test-CPermission' {
    BeforeEach {
        $Global:Error.Clear()
    }

    It 'should handle non existent path' {
        Test-CPermission -Path 'C:\I\Do\Not\Exist' -Identity $script:identity -Permission 'FullControl' -ErrorAction SilentlyContinue |
            Should -BeNullOrEmpty
        $Global:Error | Should -HaveCount 2
    }

    It 'should check ungranted permission on file system' {
        Test-CPermission @testDirPermArgs -Permission 'Write' | Should -BeFalse
    }

    It 'should check granted permission on file system' {
        Test-CPermission @testDirPermArgs -Permission 'Read' | Should -BeTrue
    }

    It 'should check exact partial permission on file system' {
        Test-CPermission @testDirPermArgs -Permission 'Read' -Exact | Should -BeFalse
    }

    It 'should check exact permission on file system' {
        Test-CPermission @testDirPermArgs -Permission 'ReadAndExecute' -Exact | Should -BeTrue
    }

    It 'should exclude inherited permission' {
        Test-CPermission @testFilePermArgs -Permission 'ReadAndExecute' | Should -BeFalse
    }

    It 'should include inherited permission' {
        Test-CPermission @testFilePermArgs -Permission 'ReadAndExecute' -Inherited | Should -BeTrue
    }

    It 'should exclude inherited partial permission' {
        Test-CPermission @testFilePermArgs -Permission 'ReadAndExecute' -Exact | Should -BeFalse
    }

    It 'should include inherited exact permission' {
        Test-CPermission @testFilePermArgs -Permission 'ReadAndExecute' -Inherited -Exact | Should -BeTrue
    }

    It 'should ignore inheritance and propagation flags on file' {
        $warning = @()
        Test-CPermission @testFilePermArgs `
                         -Permission 'ReadAndExecute' `
                         -ApplyTo SubContainers `
                         -Inherited `
                         -WarningVariable 'warning' `
                         -WarningAction SilentlyContinue |
            Should -BeTrue
        $warning | Should -Not -BeNullOrEmpty
        $warning[0] | Should -BeLike 'Can''t test inheritance/propagation rules on a leaf.*'
    }

    It 'should check ungranted permission on registry' {
        Test-CPermission -Path $script:keyPath -Identity $script:identity -Permission 'Delete' | Should -BeFalse
    }

    It 'should check granted permission on registry' {
        Test-CPermission -Path $script:keyPath -Identity $script:identity -Permission 'ReadKey' | Should -BeTrue
    }

    It 'should check exact partial permission on registry' {
        Test-CPermission -Path $script:keyPath -Identity $script:identity -Permission 'ReadKey' -Exact | Should -BeFalse
    }

    It 'should check exact permission on registry' {
        Test-CPermission -Path $script:keyPath -Identity $script:identity -Permission 'ReadKey','WriteKey' -Exact |
            Should -BeTrue
    }

    It 'should check ungranted inheritance flags' {
        Test-CPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo ContainerAndSubContainersAndLeaves  |
            Should -BeFalse
    }

    It 'should check granted inheritance flags' {
        Test-CPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo ContainerAndLeaves | Should -BeTrue
        Test-CPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo ChildLeaves  | Should -BeTrue
    }


    It 'should check exact ungranted inheritance flags' {
        Test-CPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo ContainerAndLeaves -Exact |
            Should -BeFalse
    }

    It 'should check exact granted inheritance flags' {
        Test-CPermission @testDirPermArgs -Permission 'ReadAndExecute' -ApplyTo ChildLeaves -Exact | Should -BeTrue
    }

    It 'should check permission on private key' {
        $cert = Install-CCertificate -Path $script:privateKeyPath -StoreLocation LocalMachine -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
            # PowerShell (Core) uses file system rights on private keys, not crypto key rights.
            $allPerm = 'FullControl'
            $readPerm = 'Read'
            if ([Type]::GetType('System.Security.AccessControl.CryptoKeyAccessRule'))
            {
                $allPerm = 'GenericAll'
                $readPerm = 'GenericRead'
            }
            Grant-CPermission -Path $certPath -Identity $script:identity -Permission $allPerm
            Test-CPermission -Path $certPath -Identity $script:identity -Permission $readPerm | Should -BeTrue
            Test-CPermission -Path $certPath -Identity $script:identity -Permission $readPerm -Exact |
                Should -BeFalse
            Test-CPermission -Path $certPath -Identity $script:identity -Permission $allPerm, $readPerm -Exact |
                Should -BeTrue
        }
        finally
        {
            Uninstall-CCertificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }

    $script:usesFileSystemPermsOnPrivateKeys =
        $null -eq [Type]::GetType('System.Security.AccessControl.CryptoKeyAccessRule')
    It 'should check permission on public key' -Skip:$script:usesFileSystemPermsOnPrivateKeys {
        $cert =
            Get-Item -Path 'Cert:\*\*' |
            Where-Object 'Name' -NE 'UserDS' | # This store causes problems on PowerShell 7.
            Get-ChildItem |
            Where-Object { -not $_.HasPrivateKey } |
            Select-Object -First 1
        $cert | Should -Not -BeNullOrEmpty
        $certPath = Join-Path -Path 'cert:\' -ChildPath (Split-Path -NoQualifier -Path $cert.PSPath)
        Get-CPermission -path $certPath -Identity $script:identity | Out-String | Write-Host
        Test-CPermission -Path $certPath -Identity $script:identity -Permission 'FullControl' | Should -BeTrue
        Test-CPermission -Path $certPath -Identity $script:identity -Permission 'FullControl' -Exact | Should -BeTrue
    }
}
