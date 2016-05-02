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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)

$shareName = 'CarbonGetFileSharePermission'
$sharePath = $null
$reader = 'CarbonFileShareReadr'
$writer = 'CarbonFileShareWritr'
$admin  = 'CarbonFileShareAdmin'

function Start-TestFixture
{
    $sharePath = New-TempDirectory -Prefix $PSCommandPath
    foreach( $user in ($reader,$writer,$admin) )
    {
        Install-User -Credential (New-Credential -UserName $user -Password '!m33trequ!r3m3n+s') -Description 'Carbon test user.'
    }

    Install-SmbShare -Path $sharePath -Name $shareName -ReadAccess $reader -ChangeAccess $writer -FullAccess $admin -Description 'Share for testing Carbon''s Get-FileSharePermission.'
}

function Stop-TestFixture
{
    foreach( $user in ($reader,$writer,$admin) )
    {
        Uninstall-User $user
    }
    
    Uninstall-FileShare -Name $shareName
}

function Test-ShouldGetPermissions
{
    $perms = Get-FileSharePermission -Name $shareName
    Assert-Is $perms ([object[]])
    Assert-Equal 3 $perms.Count
    
    Assert-FileSharePermission $perms $reader ([Carbon.Security.ShareRights]::Read)
    Assert-FileSharePermission $perms $writer ([Carbon.Security.ShareRights]::Change)
    Assert-FileSharePermission $perms $admin ([Carbon.Security.ShareRights]::FullControl)
}

function Test-GetUserPermission
{
    $perm = Get-FileSharePermission -Name $shareName -Identity $reader
    Assert-Is $perm ([Carbon.Security.ShareAccessRule])
    Assert-FileSharePermission $perm $reader ([Carbon.Security.ShareRights]::Read)
}

function Test-GetUserPermissionWithWildcard
{
    $perm = Get-FileSharePermission -Name $shareName -Identity '*Writr*'
    Assert-Is $perm ([Carbon.Security.ShareAccessRule])
    Assert-FileSharePermission $perm $writer ([Carbon.Security.ShareRights]::Change)
}

function Assert-FileSharePermission
{
    param(
        $Permission,

        $Identity,

        $ExpectedRights
    )

    Set-StrictMode -Version 'Latest'

    $Identity = Resolve-IdentityName -Name $Identity
    Assert-NotNull $Identity 

    $identityPerms = $Permission | Where-Object { $_.IdentityReference -eq $Identity }
    Assert-Is $identityPerms ([Carbon.Security.ShareAccessRule])
    Assert-NotNull $identityPerms
    Assert-Equal $ExpectedRights $identityPerms.ShareRights 
    Assert-Equal ([int]$ExpectedRights) $identityPerms.ShareRights
}

