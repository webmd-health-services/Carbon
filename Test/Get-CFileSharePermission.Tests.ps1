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

if (-not (Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore))
{
    $msgs = 'Get-CFileSharePermission tests will not be run because because the Get-WmiObject command does not exist.'
    Write-Warning $msgs
    return
}

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:shareName = 'CarbonGetFileSharePermission'
    $script:sharePath = $null
    $script:reader = 'CarbonFileShareReadr'
    $script:writer = 'CarbonFileShareWritr'
    $script:admin  = 'CarbonFileShareAdmin'

    $script:sharePath = Get-Item 'TestDrive:' | Select-Object -ExpandProperty 'FullName'
    foreach( $user in ($script:reader,$script:writer,$script:admin) )
    {
        if( -not (Test-CUser -Username $user) )
        {
            $cred = New-Credential -UserName $user -Password '!m33trequ!r3m3n+s'
            Install-CUser -Credential $cred -Description 'Carbon test user.'
        }
    }

    Install-CFileShare -Path $script:sharePath `
                       -Name $script:shareName `
                       -ReadAccess $script:reader `
                       -ChangeAccess $script:writer `
                       -FullAccess $script:admin `
                       -Description 'Share for testing Carbon''s Get-CFileSharePermission.'

    function Assert-FileSharePermission
    {
        param(
            $Permission,

            $Identity,

            $ExpectedRights
        )

        Set-StrictMode -Version 'Latest'

        $Identity = Resolve-CIdentityName -Name $Identity
        $Identity | Should -Not -BeNullOrEmpty

        $identityPerms = $Permission | Where-Object { $_.IdentityReference -eq $Identity }
        $identityPerms | Should -BeOfType ([Carbon.Security.ShareAccessRule])
        $identityPerms | Should -Not -BeNullOrEmpty
        $identityPerms.ShareRights | Should -Be $ExpectedRights
        $identityPerms.ShareRights | Should -Be ([int]$ExpectedRights)
    }
}

AfterAll {
    Uninstall-CFileShare -Name $script:shareName
}

Describe 'Get-CFileSharePermission' {
    It 'should get permissions' {
        $perms = Get-CFileSharePermission -Name $script:shareName
        ,$perms | Should -BeOfType ([object[]])
        $perms | Should -HaveCount 3

        Assert-FileSharePermission $perms $script:reader ([Carbon.Security.ShareRights]::Read)
        Assert-FileSharePermission $perms $script:writer ([Carbon.Security.ShareRights]::Change)
        Assert-FileSharePermission $perms $script:admin ([Carbon.Security.ShareRights]::FullControl)
    }

    It 'should get user permission' {
        $perm = Get-CFileSharePermission -Name $script:shareName -Identity $script:reader
        $perm | Should -BeOfType ([Carbon.Security.ShareAccessRule])
        Assert-FileSharePermission $perm $script:reader ([Carbon.Security.ShareRights]::Read)
    }

    It 'should get user permission with wildcard' {
        $perm = Get-CFileSharePermission -Name $script:shareName -Identity '*Writr*'
        $perm | Should -BeOfType ([Carbon.Security.ShareAccessRule])
        Assert-FileSharePermission $perm $script:writer ([Carbon.Security.ShareRights]::Change)
    }
}
