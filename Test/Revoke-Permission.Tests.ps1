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

$Path = $null
$user = 'CarbonGrantPerms'
$containerPath = $null
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve
& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$credential = New-Credential -UserName $user -Password 'a1b2c3d4!'
Install-User -Credential $credential -Description 'User for Carbon Grant-Permission tests.'

Describe 'Revoke-Permission.when user has multiple access control entries on an item' {
    $path = $TestDrive.FullName
    Grant-Permission -Path $path -Identity $credential.UserName -Permission 'Read'
    $perm = Get-Permission -Path $path -Identity $credential.UserName
    Mock -CommandName 'Get-Permission' -ModuleName 'Carbon' -MockWith { $perm ; $perm }.GetNewClosure()

    $Global:Error.Clear()

    Revoke-Permission -Path $path -Identity $credential.UserName

    It 'should not write any errors' {
        $Global:Error | Should BeNullOrEmpty
    }

    It 'should remove permission' {
        Carbon\Get-Permission -Path $path -Identity $credential.UserName | Should BeNullOrEmpty
    }
}

Describe 'Revoke-Permission' {
    BeforeEach {
        $Path = @([IO.Path]::GetTempFileName())[0]
        Grant-Permission -Path $Path -Identity $user -Permission 'FullControl'
    }
    
    AfterEach {
        if( Test-Path $Path )
        {
            Remove-Item $Path -Force
        }
    }
  
    It 'should revoke permission' {
        Revoke-Permission -Path $Path -Identity $user
        $Global:Error.Count | Should Be 0
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
    }
    
    It 'should not revoke inherited permissions' {
        Get-Permission -Path $Path -Inherited | 
            Where-Object { $_.IdentityReference -notlike ('*{0}*' -f $user) } |
            ForEach-Object {
                $result = Revoke-Permission -Path $Path -Identity $_.IdentityReference
                $Global:Error.Count | Should Be 0
                $result | Should BeNullOrEmpty
                (Test-Permission -Identity $_.IdentityReference -Path $Path -Inherited -Permission $_.FileSystemRights) | Should Be $true
            }
    }
    
    It 'should handle revoking non existent permission' {
        Revoke-Permission -Path $Path -Identity $user
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
        Revoke-Permission -Path $Path -Identity $user
        $Global:Error.Count | Should Be 0
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
    }
    
    It 'should resolve relative path' {
        Push-Location -Path (Split-Path -Parent -Path $Path)
        try
        {
            Revoke-Permission -Path ('.\{0}' -f (Split-Path -Leaf -Path $Path)) -Identity $user
            (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $false
        }
        finally
        {
            Pop-Location
        }
    }
    
    It 'should support what if' {
        Revoke-Permission -Path $Path -Identity $user -WhatIf
        (Test-Permission -Path $Path -Identity $user -Permission 'FullControl') | Should Be $true
    }
    
    It 'should revoke permission on registry' {
        $regKey = 'hkcu:\TestRevokePermissions'
        New-Item $regKey
        
        try
        {
            Grant-Permission -Identity $user -Permission 'ReadKey' -Path $regKey
            $result = Revoke-Permission -Path $regKey -Identity $user
            $result | Should BeNullOrEmpty
            (Test-Permission -Path $regKey -Identity $user -Permission 'ReadKey') | Should Be $false
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
            (Get-Permission -Path $certPath -Identity $user) | Should Not BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user
            $Global:Error.Count | Should Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should BeNullOrEmpty
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
            $Global:Error.Count | Should Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should BeNullOrEmpty
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
            (Get-Permission -Path $certPath -Identity $user) | Should Not BeNullOrEmpty
            Revoke-Permission -Path $certPath -Identity $user -WhatIf
            $Global:Error.Count | Should Be 0
            (Get-Permission -Path $certPath -Identity $user) | Should Not BeNullOrEmpty
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My -NoWarn
        }
    }
    
}
