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

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

Describe 'Get-FileSharePermission' {
    $shareName = 'CarbonGetFileSharePermission'
    $sharePath = $null
    $reader = 'CarbonFileShareReadr'
    $writer = 'CarbonFileShareWritr'
    $admin  = 'CarbonFileShareAdmin'

    $sharePath = Get-Item 'TestDrive:' | Select-Object -ExpandProperty 'FullName'
    foreach( $user in ($reader,$writer,$admin) )
    {
        if( -not (Test-User -Username $user) )
        {
            Install-User -Credential (New-Credential -UserName $user -Password '!m33trequ!r3m3n+s') -Description 'Carbon test user.'
        }
    }

    Install-SmbShare -Path $sharePath -Name $shareName -ReadAccess $reader -ChangeAccess $writer -FullAccess $admin -Description 'Share for testing Carbon''s Get-FileSharePermission.'
    
    function Assert-FileSharePermission
    {
        param(
            $Permission,
    
            $Identity,
    
            $ExpectedRights
        )
    
        Set-StrictMode -Version 'Latest'
    
        $Identity = Resolve-IdentityName -Name $Identity
        $Identity | Should Not BeNullOrEmpty
    
        $identityPerms = $Permission | Where-Object { $_.IdentityReference -eq $Identity }
        $identityPerms | Should BeOfType ([Carbon.Security.ShareAccessRule])
        $identityPerms | Should Not BeNullOrEmpty
        $identityPerms.ShareRights | Should Be $ExpectedRights
        $identityPerms.ShareRights | Should Be ([int]$ExpectedRights)
    }
    
    try
    {
        It 'should get permissions' {
            $perms = Get-FileSharePermission -Name $shareName
            ,$perms | Should BeOfType ([object[]])
            $perms.Count | Should Be 3
        
            Assert-FileSharePermission $perms $reader ([Carbon.Security.ShareRights]::Read)
            Assert-FileSharePermission $perms $writer ([Carbon.Security.ShareRights]::Change)
            Assert-FileSharePermission $perms $admin ([Carbon.Security.ShareRights]::FullControl)
        }
    
        It 'get user permission' {
            $perm = Get-FileSharePermission -Name $shareName -Identity $reader
            $perm | Should BeOfType ([Carbon.Security.ShareAccessRule])
            Assert-FileSharePermission $perm $reader ([Carbon.Security.ShareRights]::Read)
        }
    
        It 'get user permission with wildcard' {
            $perm = Get-FileSharePermission -Name $shareName -Identity '*Writr*'
            $perm | Should BeOfType ([Carbon.Security.ShareAccessRule])
            Assert-FileSharePermission $perm $writer ([Carbon.Security.ShareRights]::Change)
        }
    }
    finally
    {    
        Uninstall-FileShare -Name $shareName
    }

}
