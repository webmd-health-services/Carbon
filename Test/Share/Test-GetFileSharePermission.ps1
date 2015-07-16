# Copyright 2012 Aaron Jensen
# 
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

function Test-ShouldGetPermissions
{
    $tempDir = New-TempDirectory -Prefix $PSCommandPath
    $reader = 'CarbonFileShareReadr'
    $writer = 'CarbonFileShareWritr'
    $admin  = 'CarbonFileShareAdmin'
    foreach( $user in ($reader,$writer,$admin) )
    {
        Install-User -Credential (New-Credential -UserName $user -Password '!m33trequ!r3m3n+s') -Description 'Carbon test user.'
    }

    $shareName = 'CarbonGetFileSharePermission'
    Install-SmbShare -Path $tempDir -Name $shareName -ReadAccess $reader -ChangeAccess $writer -FullAccess $admin -Description 'Share for testing Carbon''s Get-FileSharePermission.'

    try
    {
        $perms = Get-FileSharePermission -Name $shareName
        Assert-Is $perms ([object[]])
        Assert-Equal 3 $perms.Count
    
        Assert-FileSharePermission $perms $reader ([Carbon.Security.ShareRights]::Read -bor [Carbon.Security.ShareRights]::Synchronize)
        Assert-FileSharePermission $perms $writer ([Carbon.Security.ShareRights]::Change -bor [Carbon.Security.ShareRights]::Synchronize)
        Assert-FileSharePermission $perms $admin ([Carbon.Security.ShareRights]::FullControl -bor [Carbon.Security.ShareRights]::Synchronize)
    }
    finally
    {
        Get-FileShare -Name $shareName | ForEach-Object { $_.Delete() }
    }
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