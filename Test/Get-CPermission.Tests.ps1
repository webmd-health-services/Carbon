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

    $script:user = 'CarbonTestUser1'
    $script:group1 = 'CarbonTestGroup1'
    $script:password = 'a1z2b3y4!'
    $script:containerPath = $null
    $script:childPath = $null

}

Describe 'Get-CPermission' {
    BeforeEach {
        Install-CUser -Username $script:user -Password $script:password -Description 'Carbon test script:user 1'
        Install-CGroup -Name $script:group1 -Description 'Carbon test group 1'

        $script:containerPath = 'Carbon-Test-GetPermissions-{0}' -f ([IO.Path]::GetRandomFileName())
        $script:containerPath = Join-Path $env:Temp $script:containerPath

        Install-CDirectory $script:containerPath
        Grant-CPermission -Path $script:containerPath -Identity $script:group1 -Permission Read -NoWarn

        $script:childPath = Join-Path $script:containerPath 'Child1'
        $null = New-Item $script:childPath -ItemType File
        Grant-CPermission -Path $script:childPath -Identity $script:user -Permission Read -NoWarn

        $Global:Error.Clear()
    }

    It 'should get permissions' {
        $perms = Get-CPermission -Path $script:childPath -NoWarn
        $perms | Should -Not -BeNullOrEmpty
        $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:group1" }
        $group1Perms | Should -BeNullOrEmpty

        $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:user" }
        $userPerms | Should -Not -BeNullOrEmpty
        $userPerms | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]
    }

    It 'should get inherited permissions' {
        $perms = Get-CPermission -Path $script:childPath -Inherited -NoWarn
        $perms | Should -Not -BeNullOrEmpty
        $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:group1" }
        $group1Perms | Should -Not -BeNullOrEmpty
        $group1Perms | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]

        $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:user" }
        $userPerms | Should -Not -BeNullOrEmpty
        $userPerms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
    }

    It 'should get specific script:user permissions' {
        $perms = Get-CPermission -Path $script:childPath -Identity $script:group1 -NoWarn
        $perms | Should -BeNullOrEmpty

        $perms = @( Get-CPermission -Path $script:childPath -Identity $script:user -NoWarn )
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -HaveCount 1
        $perms[0] | Should -Not -BeNullOrEmpty
        $perms[0] | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]
    }

    It 'should get specific users inherited permissions' {
        $perms = Get-CPermission -Path $script:childPath -Identity $script:group1 -Inherited -NoWarn
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
    }

    It 'should get permissions on registry key' {
        $perms = Get-CPermission -Path 'hkcu:\' -NoWarn
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -BeOfType [Security.AccessControl.RegistryAccessRule]
    }

    It 'should get private cert permission' {
        $certs =
            Get-Item -Path 'Cert:\*\*' |
            Where-Object 'Name' -NE 'UserDS' | # This store causes problems on PowerShell 7.
            Get-ChildItem |
            Where-Object { -not $_.PsIsContainer } |
            Where-Object { $_.HasPrivateKey }

        foreach ($cert in $certs)
        {
            $expectedType = [Security.AccessControl.FileSystemAccessRule]
            if ($cert.PrivateKey -and `
                ($cert.PrivateKey | Get-Member -Name 'CspKeyContainerInfo') -and `
                [Type]::GetType('System.Security.AccessControl.CryptoKeyAccessRule'))
            {
                $expectedType = [Security.AccessControl.CryptoKeyAccessRule]
            }
            $certPath = Join-Path -Path 'cert:' -ChildPath ($cert.PSPath | Split-Path -NoQualifier)
            if ($cert.Thumbprint -eq '3044F98A1B1AB539E78FCD01FE8AFD58EF0B8BA6')
            {
                Write-Debug 'break'
            }
            $numErrors = $Global:Error.Count
            $perms = Get-CPermission -Path $certPath -Inherited -NoWarn -ErrorAction SilentlyContinue
            if ($numErrors -ne $Global:Error.Count -and `
                ($Global:Error[0] -match '(keyset does not exist)|(Invalid provider type specified)'))
            {
                continue
            }
            $perms | Should -Not -BeNullOrEmpty -Because "${certPath} should have private key permissions"
            $perms | Should -BeOfType $expectedType
        }
    }

    It 'should get specific identity cert permission' {
        Get-Item -Path 'Cert:\*\*' |
            Where-Object 'Name' -NE 'UserDS' | # This store causes problems on PowerShell 7.
            Get-ChildItem |
            Where-Object { -not $_.PsIsContainer } |
            Where-Object { $_.HasPrivateKey } |
            Where-Object { $_.PrivateKey } |
            ForEach-Object { Join-Path -Path 'cert:' -ChildPath (Split-Path -NoQualifier -Path $_.PSPath) } |
            ForEach-Object {
                [Object[]]$rules = Get-CPermission -Path $_ -NoWarn
                foreach( $rule in $rules )
                {
                    [Object[]]$identityRule = Get-CPermission -Path $_ -Identity $rule.IdentityReference.Value -NoWarn
                    $identityRule | Should -Not -BeNullOrEmpty
                    $identityRule.Count | Should -BeLessOrEqual $rules.Count
                }
            }
    }

    It 'gets permissions for cng private key' {
        $certFilePath = Join-Path -Path $PSScriptRoot -ChildPath 'Certificates\CarbonRsaCng.pfx' -Resolve
        $cert = Install-CCertificate -Path $certFilePath -StoreLocation CurrentUser -StoreName My
        try
        {
            $perms = Get-CPermission -Path (Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $cert.Thumbprint) `
                                     -Inherited `
                                     -NoWarn
            $perms | Should -Not -BeNullOrEmpty
            $perms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
        }
        finally
        {
            Uninstall-CCertificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
        }
    }
}
