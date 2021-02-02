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

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

$Path = $null
$user = 'CarbonGrantPerms'
$user2 = 'CarbonGrantPerms2'
$containerPath = $null
$regContainerPath = $null
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath 'Cryptography\CarbonTestPrivateKey.pfx' -Resolve

Install-User -Credential (New-Credential -Username $user -Password 'a1b2c3d4!') -Description 'User for Carbon Grant-Permission tests.'
Install-User -Credential (New-Credential -Username $user2 -Password 'a1b2c3d4!') -Description 'User for Carbon Grant-Permission tests.'
    
function Assert-InheritanceFlags
{
    param(
        [string]
        $ContainerInheritanceFlags,
            
        [Security.AccessControl.InheritanceFlags]
        $InheritanceFlags,
            
        [Security.AccessControl.PropagationFlags]
        $PropagationFlags
    )
    
    $ace = Get-Permission $containerPath -Identity $user
                    
    $ace | Should Not BeNullOrEmpty
    $expectedRights = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Synchronize
    It ('should set file system rights to {0}' -f $expectedRights) {
        $ace.FileSystemRights | Should Be $expectedRights
    }
    It ('should set inhertance flags to {0}' -f $InheritanceFlags) {
        $ace.InheritanceFlags | Should Be $InheritanceFlags
    }
    It ('shuld set propagation flags to {0}' -f $PropagationFlags) {
        $ace.PropagationFlags | Should Be $PropagationFlags
    }
}
    
function Assert-Permissions
{
    param(
        $identity, 
        $permissions, 
        $path,
        $ApplyTo,
        $Type = 'Allow'
    )

    $providerName = (Get-PSDrive (Split-Path -Qualifier (Resolve-Path $path)).Trim(':')).Provider.Name
    if( $providerName -eq 'Certificate' )
    {
        $providerName = 'CryptoKey'
    }
        
    $rights = 0
    foreach( $permission in $permissions )
    {
        $rights = $rights -bor ($permission -as "Security.AccessControl.$($providerName)Rights")
    }
        
    $ace = Get-Permission -Path $path -Identity $identity
    $ace | Should Not BeNullOrEmpty
        
    if( $ApplyTo )
    {
        $expectedInheritanceFlags = ConvertTo-InheritanceFlag -ContainerInheritanceFlag $ApplyTo
        $expectedPropagationFlags = ConvertTo-PropagationFlag -ContainerInheritanceFlag $ApplyTo
    }
    else
    {
        $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
        $expectedPropagationFlags = [Security.AccessControl.PropagationFlags]::None
        if( Test-Path $path -PathType Container )
        {
            $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                                        [Security.AccessControl.InheritanceFlags]::ObjectInherit
        }
    }

    It ('should set inheritance flags to {0}' -f $expectedInheritanceFlags) {
        $ace.InheritanceFlags | Should Be $expectedInheritanceFlags
    }

    It ('should set propagation flags to {0}' -f $expectedPropagationFlags ) {
        $ace.PropagationFlags | Should Be $expectedPropagationFlags
    }

    It ('should set permissions to {0}' -f $rights) {
        $rights | Should Be ($ace."$($providerName)Rights" -band $rights)
    }

   It ('should create {0} rule' -f $Type) {
        $ace.AccessControlType | Should Be ([Security.AccessControl.AccessControlType]$Type)
   }
}

function Invoke-GrantPermissions
{
    param(
        $Identity, 
        $Permissions, 
        $Path,
        $ApplyTo,
        $ExpectedRuleType = 'FileSystem',
        [Switch]
        $Clear,
        $ExpectedPermission,
        $Type
    )

    $optionalParams = @{ }
    $assertOptionalParams = @{ }
    if( $ApplyTo )
    {
        $optionalParams['ApplyTo'] = $ApplyTo
        $assertOptionalParams['ApplyTo'] = $ApplyTo
    }

    if( $Clear )
    {
        $optionalParams['Clear'] = $Clear
    }

    if( $Type )
    {
        $optionalParams['Type'] = $Type
        $assertOptionalParams['Type'] = $Type
    }

    $ExpectedRuleType = [Type]('Security.AccessControl.{0}AccessRule' -f $ExpectedRuleType)
    $result = Grant-Permission -Identity $Identity -Permission $Permissions -Path $path -PassThru @optionalParams
    It ('should return a {0}' -f $ExpectedRuleType.Name) {
        $result | Should Not BeNullOrEmpty
        $result.IdentityReference | Should Be (Resolve-IdentityName $Identity)
        $result | Should BeOfType $ExpectedRuleType
    }
    if( -not $ExpectedPermission )
    {
        $ExpectedPermission = $Permissions
    }

    Assert-Permissions $Identity $ExpectedPermission $Path @assertOptionalParams
}
    
function New-TestContainer
{
    param(
        [Switch]
        $FileSystem,
        [Switch]
        $Registry
    )

    if( $FileSystem )
    {
        $path = Join-Path -Path (Get-Item -Path 'TestDrive:').FullName -ChildPath ([IO.Path]::GetRandomFileName())
        Install-Directory -Path $path
        return $path
    }

    if( $Registry )
    {
        $regContainerPath = 'hkcu:\CarbonTestGrantPermission{0}' -f ([IO.Path]::GetRandomFileName())
        $key = New-Item -Path $regContainerPath 
        return $regContainerPath
    }
}

function New-TestFile
{
    param(
    )

    $containerPath = New-TestContainer -FileSystem

    $leafPath = Join-Path -Path $containerPath -ChildPath ([IO.Path]::GetRandomFileName())
    $null = New-Item -ItemType 'File' -Path $leafPath
    return $leafPath
}

Describe 'Grant-Permission.when changing permissions on a file' {
    $file = New-TestFile
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
        
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions -Path $file
}
    
Describe 'Grant-Permission.when changing permissions on a directory' {
    $dir = New-TestContainer -FileSystem
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
        
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions -Path $dir
}
    
Describe 'Grant-Permission.when changing permissions on registry key' {
    $regKey = New-TestContainer -Registry

    Invoke-GrantPermissions -Identity 'BUILTIN\Administrators' -Permission 'ReadKey' -Path $regKey -ExpectedRuleType 'Registry'
}
    
Describe 'Grant-Permission.when passing an invalid permission' {
    $path = New-TestFile
    $failed = $false
    $error.Clear()
    $result = Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'BlahBlahBlah' -Path $path -PassThru -ErrorAction SilentlyContinue
    It 'should not return anything' {
        $result | Should BeNullOrEmpty
    }

    It 'should write errors' {
        $error.Count | Should Be 2
    }
}
    
Describe 'Grant-Permission.when clearing existing permissions' {
    $path = New-TestFile
    Invoke-GrantPermissions $user 'FullControl' -Path $path
    Invoke-GrantPermissions $user2 'FullControl' -Path $path
        
    $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $path -Clear -PassThru
    It 'should return an object' {
        $result | Should Not BeNullOrEmpty
        $result.Path | Should Be $Path
    }
        
    $acl = Get-Acl -Path $path
    
    $rules = $acl.Access |
                Where-Object { -not $_.IsInherited }
    It 'should clear previous permissions' {
        $rules | Should Not BeNullOrEmpty
        $rules.IdentityReference.Value | Should Be 'Everyone'
    }
}
    
Describe 'Grant-Permission.when there are no existing permissions to clear' {
    $Global:Error.Clear()

    $path = New-TestFile

    $acl = Get-Acl -Path $path
    $rules = $acl.Access | Where-Object { -not $_.IsInherited }
    if( $rules )
    {
        $rules | ForEach-Object { $acl.RemoveAccessRule( $_ ) }
        Set-Acl -Path $path -AclObject $acl
    }
        
    $error.Clear()
    $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $path -Clear -PassThru -ErrorAction SilentlyContinue
    It 'should return an object' {
        $result | Should Not BeNullOrEmpty
        $result.IdentityReference | Should Be 'Everyone'
    }

    It 'should not write an error' {
        $error.Count | Should Be 0
    }

    $acl = Get-Acl -Path $path
    $rules = $acl.Access | Where-Object { -not $_.IsInherited }
    It 'should set permission' {
        $rules | Should Not BeNullOrEmpty
        ($rules.IdentityReference.Value -like 'Everyone') | Should Be $true
    }
}

Describe 'Grant-Permission.when setting inheritance flags' {
    function New-FlagsObject
    {
        param(
            [Security.AccessControl.InheritanceFlags]
            $InheritanceFlags,
                
            [Security.AccessControl.PropagationFlags]
            $PropagationFlags
        )
           
        New-Object PsObject -Property @{ 'InheritanceFlags' = $InheritanceFlags; 'PropagationFlags' = $PropagationFlags }
    }
        
    $IFlags = [Security.AccessControl.InheritanceFlags]
    $PFlags = [Security.AccessControl.PropagationFlags]
    $map = @{
        # ContainerInheritanceFlags                                    InheritanceFlags                     PropagationFlags
        'Container' =                                 (New-FlagsObject $IFlags::None                               $PFlags::None)
        'ContainerAndSubContainers' =                 (New-FlagsObject $IFlags::ContainerInherit                   $PFlags::None)
        'ContainerAndLeaves' =                        (New-FlagsObject $IFlags::ObjectInherit                      $PFlags::None)
        'SubContainersAndLeaves' =                    (New-FlagsObject ($IFlags::ContainerInherit -bor $IFlags::ObjectInherit)   $PFlags::InheritOnly)
        'ContainerAndChildContainers' =               (New-FlagsObject $IFlags::ContainerInherit                   $PFlags::NoPropagateInherit)
        'ContainerAndChildLeaves' =                   (New-FlagsObject $IFlags::ObjectInherit                      $PFlags::NoPropagateInherit)
        'ContainerAndChildContainersAndChildLeaves' = (New-FlagsObject ($IFlags::ContainerInherit -bor $IFlags::ObjectInherit)   $PFlags::NoPropagateInherit)
        'ContainerAndSubContainersAndLeaves' =        (New-FlagsObject ($IFlags::ContainerInherit -bor $IFlags::ObjectInherit)   $PFlags::None)
        'SubContainers' =                             (New-FlagsObject $IFlags::ContainerInherit                   $PFlags::InheritOnly)
        'Leaves' =                                    (New-FlagsObject $IFlags::ObjectInherit                      $PFlags::InheritOnly)
        'ChildContainers' =                           (New-FlagsObject $IFlags::ContainerInherit                   ($PFlags::InheritOnly -bor $PFlags::NoPropagateInherit))
        'ChildLeaves' =                               (New-FlagsObject $IFlags::ObjectInherit                      ($PFlags::InheritOnly -bor $PFlags::NoPropagateInherit))
        'ChildContainersAndChildLeaves' =             (New-FlagsObject ($IFlags::ContainerInherit -bor $IFlags::ObjectInherit)   ($PFlags::InheritOnly -bor $PFlags::NoPropagateInherit))
    }
    
    foreach( $containerInheritanceFlag in $map.Keys )
    {
        Context $containerInheritanceFlag {
            $containerPath = New-TestContainer -FileSystem
                    
            $childLeafPath = Join-Path $containerPath 'ChildLeaf'
            $null = New-Item $childLeafPath -ItemType File
                    
            $childContainerPath = Join-Path $containerPath 'ChildContainer'
            $null = New-Item $childContainerPath -ItemType Directory
                    
            $grandchildContainerPath = Join-Path $childContainerPath 'GrandchildContainer'
            $null = New-Item $grandchildContainerPath -ItemType Directory
                    
            $grandchildLeafPath = Join-Path $childContainerPath 'GrandchildLeaf'
            $null = New-Item $grandchildLeafPath -ItemType File
    
            $flags = $map[$containerInheritanceFlag]
            Invoke-GrantPermissions -Identity $user -Path $containerPath -Permission Read -ApplyTo $containerInheritanceFlag
        }
    }
}

Describe 'Grant-Permission.when setting inheritance flags on a file' {
    $path = New-TestFile
    $warnings = @()
    $result = Grant-CPermission -Identity $user -Permission Read -Path $path -ApplyTo Container -WarningAction SilentlyContinue -WarningVariable 'warnings'
    It 'should warn that you can''t do that' {
        $warnings | Should Not BeNullOrEmpty
        ($warnings[0] -like '*Can''t apply inheritance/propagation rules to a leaf*') | Should Be $true
    }
}

Describe 'Grant-Permission.when a user already has a different permission' {
    $containerPath = New-TestContainer -FileSystem
    Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath -ApplyTo Container
    Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath -Apply Container
}
    
Describe 'Grant-Permission.when a user already has the permissions' {
    $containerPath = New-TestContainer -FileSystem
    
    Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath

    Mock -CommandName 'Set-Acl' -Verifiable -ModuleName 'Carbon'

    Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath 
    It 'should not set permissions again' {
        Assert-MockCalled -CommandName 'Set-Acl' -Times 0 -ModuleName 'Carbon'
    }
}
    
Describe 'Grant-Permission.when changing inheritance flags' {
    $containerPath = New-TestContainer -FileSystem
    Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves
    Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath -ApplyTo Container
}
    
Describe 'Grant-Permission.when forcing a permission change and the user already has the permissions' {
    $containerPath = New-TestContainer -FileSystem

    Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves

    Mock -CommandName 'Set-Acl' -Verifiable -ModuleName 'Carbon'

    Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -Apply ContainerAndLeaves -Force

    It 'should set the permissions' {
        Assert-MockCalled -CommandName 'Set-Acl' -Times 1 -Exactly -ModuleName 'Carbon'
    }
}

Describe 'Grant-Permission.when an item is hidden' {
    $Global:Error.Clear()

    $path = New-TestFile
    $item = Get-Item -Path $path
    $item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden
    
    $result = Invoke-GrantPermissions -Identity $user -Permission Read -Path $path
    It 'should not write any error' {
        $Global:Error.Count | Should Be 0
    }
}
    
Describe 'Grant-Permission.when the path does not exist' {
    $Global:Error.Clear()

    $result = Grant-Permission -Identity $user -Permission Read -Path 'C:\I\Do\Not\Exist' -PassThru -ErrorAction SilentlyContinue
    It 'should not return anything' {
        $result | Should BeNullOrEmpty
    }

    It 'should write error' {
        $Global:Error.Count | Should BeGreaterThan 0
        $Global:Error[0] | Should Match 'Cannot find path'
    }
}
    
Describe 'Grant-Permission.when clearing a permission that already exists on a file' {
    $Global:Error.Clear()
    $path = New-TestFile
    Invoke-GrantPermissions -Identity $user -Permission Read -Path $Path 
    Invoke-GrantPermissions -Identity $user -Permission Read -Path $Path -Clear
    It 'should not write error' {
        $Global:Error | Should BeNullOrEmpty
    }
}

Describe 'Grant-Permission.when clearing permissions that already exist on a directory' {
    $Global:Error.Clear()

    $containerPath = New-TestContainer -FileSystem

    Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath
    Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath -Clear

    It 'should not write error' {
        $Global:Error | Should BeNullOrEmpty
    }
}
    
Describe 'Grant-Permission.when clearing permissions that already exist on a registry key' {
    $Global:Error.Clear()
    $regContainerPath = New-TestContainer -Registry
    Invoke-GrantPermissions -Identity $user -Permission QueryValues -Path $regContainerPath -ExpectedRuleType 'Registry'
    Invoke-GrantPermissions -Identity $user -Permission QueryValues -Path $regContainerPath -ExpectedRuleType 'Registry' -Clear


    It 'should not write error' {
        $Global:Error | Should BeNullOrEmpty
    }
}
    
Describe 'Grant-Permission.when clearing permissions on the file system and verbose preference is continue' {
    $containerPath = New-TestContainer -FileSystem

    $result = Grant-Permission -Identity $user -Permission Read -Path $containerPath -Verbose 4>&1
    It 'should write verbose message' {
        $result | Should BeOfType 'Management.Automation.VerboseRecord'
    }

    $result = Grant-Permission -Identity $user2 -Permission Read -Path $containerPath -Clear -Verbose 4>&1
    It 'should write verbose messages showing cleared permissions' {
        $result | Should Not BeNullOrEmpty
        ($result.Count -ge 2) | Should Be $true
        for( $idx = 0; $idx -lt $result.Count - 1; ++$idx )
        {
            $result[$idx] | Should BeOfType 'Management.Automation.VerboseRecord'
            ($result[$idx].Message -like ('*{0}* -> ' -f $user)) | Should Be $true
        }
    }
}

Describe 'Grant-Permission.when clearing permissions on a registry key and verbose preference is continue' {
    $regContainerPath = New-TestContainer -Registry
    $result = Grant-Permission -Identity $user -Permission QueryValues -Path $regContainerPath -Verbose 4>&1
    it 'should write verbose messages' {
        $result | Should BeOfType 'Management.Automation.VerboseRecord'
    }

    $result = Grant-Permission -Identity $user2 -Permission QueryValues -Path $regContainerPath -Clear -Verbose 4>&1
    It 'should write verbose messages showing cleared permissions' {
        $result | Should Not BeNullOrEmpty
        $result.Count | Should Be 2
        $result[0] | Should BeOfType 'Management.Automation.VerboseRecord'
        ($result[0].Message -like ('*QueryValues -> ' -f $user)) | Should Be $true
        $result[1] | Should BeOfType 'Management.Automation.VerboseRecord'
        ($result[1].Message -like ('* -> QueryValues' -f $user)) | Should Be $true
    }
}

foreach( $location in @( 'LocalMachine','CurrentUser' ) )
{
    Describe ('Grant-Permission.when setting permissions on a private key in the {0} location' -f $location) {
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation $location -StoreName My -NoWarn
        try
        {
            It 'should install the certificate' {
                $cert | Should Not BeNullOrEmpty
            }

            $certPath = Join-Path -Path ('cert:\{0}\My' -f $location) -ChildPath $cert.Thumbprint
            Context 'adds permissions' {
                Invoke-GrantPermissions -Path $certPath -Identity $user -Permission 'GenericWrite' -ExpectedRuleType 'CryptoKey' -ExpectedPermission 'GenericRead','GenericAll'
            }

            Context 'changes permissions' {
                Invoke-GrantPermissions -Path $certPath -Identity $user -Permission 'GenericRead' -ExpectedRuleType 'CryptoKey' 
            }
        
            Context 'clearing others'' permissions' {
                Invoke-GrantPermissions -Path $certPath -Identity $user2 -Permission 'GenericRead' -ExpectedRuleType 'CryptoKey' -Clear
                It 'should remove the other user''s permissions' {
                    (Test-Permission -Path $certPath -Identity $user -Permission 'GenericRead') | Should Be $false
                }
            }

            Context 'clearing others'' permissions when permissions getting set haven''t changed' {
                Invoke-GrantPermissions -Path $certPath -Identity $user -Permission 'GenericRead' -ExpectedRuleType 'CryptoKey' 
                Invoke-GrantPermissions -Path $certPath -Identity $user2 -Permission 'GenericRead' -ExpectedRuleType 'CryptoKey' -Clear
                It 'should remove the other user''s permissions' {
                    (Test-Permission -Path $certPath -Identity $user -Permission 'GenericRead') | Should Be $false
                }
            }

            Context 'running with -WhatIf switch' {
                Grant-Permission -Path $certPath -Identity $user2 -Permission 'GenericWrite' -WhatIf
                It 'should not change the user''s permissions' {
                    Test-Permission -Path $certPath -Identity $user2 -Permission 'GenericRead' -Exact | Should Be $true
                    Test-Permission -Path $certPath -Identity $user2 -Permission 'GenericWrite' -Exact | Should Be $false
                }
            }

            Context 'creating a deny rule' {
                Invoke-GrantPermissions -Path $certPath -Identity $user -Permission 'GenericRead' -Type 'Deny' -ExpectedRuleType 'CryptoKey'
            }

            Mock -CommandName 'Set-CryptoKeySecurity' -Verifiable -ModuleName 'Carbon' 

            Context 'permissions exist' {
            # Now, check that permissions don't get re-applied.
                Grant-Permission -Path $certPath -Identity $user2 -Permission 'GenericRead'
                It 'should not set the permissions' {
                    Assert-MockCalled -CommandName 'Set-CryptoKeySecurity' -ModuleName 'Carbon' -Times 0
                }
            }

            Context 'permissions exist but forcing the change' {
                Grant-Permission -Path $certPath -Identity $user2 -Permission 'GenericRead' -Force 
                It 'should set the permissions' {
                    Assert-MockCalled -CommandName 'Set-CryptoKeySecurity' -ModuleName 'Carbon' -Times 1 -Exactly
                }
            }
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation $location -StoreName My -NoWarn
        }
    }
}

Describe 'Grant-Permission.when setting Deny rule on file system' {
    $filePath = New-TestFile
    Invoke-GrantPermissions -Identity $user -Permissions 'Write' -Path $filePath -Type 'Deny'
}

Describe 'Grant-Permission.when setting Deny rule on registry' {
    $path = New-TestContainer -Registry
    Invoke-GrantPermissions -Identity $user -Permissions 'Write' -Path $path -Type 'Deny' -ExpectedRuleType 'Registry'
}

Describe 'Grant-Permission.when granting multiple different rules to a user on the file system' {
    $dirPath = New-TestContainer -FileSystem
    Grant-CPermission -Path $dirPath -Identity $user -Permission 'Read' -ApplyTo ContainerAndSubContainersAndLeaves -Append
    Grant-CPermission -Path $dirPath -Identity $user -Permission 'Write' -ApplyTo ContainerAndLeaves -Append
    $perm = Get-CPermission -Path $dirPath -Identity $user
    It ('should grant multiple permissions') {
        $perm | Should -HaveCount 2
    }
}
