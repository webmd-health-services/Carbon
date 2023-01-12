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
        Grant-CPermission -Path $script:containerPath -Identity $script:group1 -Permission Read

        $script:childPath = Join-Path $script:containerPath 'Child1'
        $null = New-Item $script:childPath -ItemType File
        Grant-CPermission -Path $script:childPath -Identity $script:user -Permission Read

        $Global:Error.Clear()
    }

    It 'should get permissions' {
        $perms = Get-CPermission -Path $script:childPath
        $perms | Should -Not -BeNullOrEmpty
        $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:group1" }
        $group1Perms | Should -BeNullOrEmpty

        $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:user" }
        $userPerms | Should -Not -BeNullOrEmpty
        $userPerms | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]
    }

    It 'should get inherited permissions' {
        $perms = Get-CPermission -Path $script:childPath -Inherited
        $perms | Should -Not -BeNullOrEmpty
        $group1Perms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:group1" }
        $group1Perms | Should -Not -BeNullOrEmpty
        $group1Perms | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]

        $userPerms = $perms | Where-Object { $_.IdentityReference.Value -like "*\$script:user" }
        $userPerms | Should -Not -BeNullOrEmpty
        $userPerms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
    }

    It 'should get specific script:user permissions' {
        $perms = Get-CPermission -Path $script:childPath -Identity $script:group1
        $perms | Should -BeNullOrEmpty

        $perms = @( Get-CPermission -Path $script:childPath -Identity $script:user )
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -HaveCount 1
        $perms[0] | Should -Not -BeNullOrEmpty
        $perms[0] | Should -BeOfType [Security.AccessControl.FileSystemAccessrule]
    }

    It 'should get specific users inherited permissions' {
        $perms = Get-CPermission -Path $script:childPath -Identity $script:group1 -Inherited
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -BeOfType [Security.AccessControl.FileSystemAccessRule]
    }

    It 'should get permissions on registry key' {
        $perms = Get-CPermission -Path 'hkcu:\'
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -BeOfType [Security.AccessControl.RegistryAccessRule]
    }

    It 'should get private cert permission' {
        $perms =
            Get-ChildItem -Path 'Cert:\*\*' -Recurse |
            Where-Object { -not $_.PsIsContainer } |
            Where-Object { $_.HasPrivateKey } |
            Where-Object { $_.PrivateKey } |
            ForEach-Object { Join-Path -Path 'cert:' -ChildPath (Split-Path -NoQualifier -Path $_.PSPath) } |
            ForEach-Object { Get-CPermission -Path $_ }
        $perms | Should -Not -BeNullOrEmpty
        $perms | Should -BeOfType [Security.AccessControl.CryptoKeyAccessRule]
    }

    It 'should get specific identity cert permission' {
        Get-ChildItem -Path 'Cert:\*\*' -Recurse |
            Where-Object { -not $_.PsIsContainer } |
            Where-Object { $_.HasPrivateKey } |
            Where-Object { $_.PrivateKey } |
            ForEach-Object { Join-Path -Path 'cert:' -ChildPath (Split-Path -NoQualifier -Path $_.PSPath) } |
            ForEach-Object {
                [Object[]]$rules = Get-CPermission -Path $_
                foreach( $rule in $rules )
                {
                    [Object[]]$identityRule = Get-CPermission -Path $_ -Identity $rule.IdentityReference.Value
                    $identityRule | Should -Not -BeNullOrEmpty
                    $identityRule.Count | Should -BeLessOrEqual $rules.Count
                }
            }
    }
}
