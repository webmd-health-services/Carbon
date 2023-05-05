
#Requires -Version 5.1
Set-StrictMode -Version 'Latest'

BeforeAll {
    Set-StrictMode -Version 'Latest'

    & (Join-Path -Path $PSScriptRoot -ChildPath 'Initialize-CarbonTest.ps1' -Resolve)

    $script:testDirPath = $null
    $script:testNum = 0

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

        $ace | Should -Not -BeNullOrEmpty
        $expectedRights = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Synchronize
        $ace.FileSystemRights | Should -Be $expectedRights
        $ace.InheritanceFlags | Should -Be $InheritanceFlags
        $ace.PropagationFlags | Should -Be $PropagationFlags
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
            # CryptoKey does not exist in .NET standard/core so we will have to use FileSystem instead
            if( -not (Invoke-CPrivateCommand -Name 'Test-CCryptoKeyAvailable') )
            {
                $providerName = 'FileSystem'
            }
        }

        $rights = 0
        foreach( $permission in $permissions )
        {
            $rights = $rights -bor ($permission -as "Security.AccessControl.$($providerName)Rights")
        }

        $ace = Get-Permission -Path $path -Identity $identity
        $ace | Should -Not -BeNullOrEmpty

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

        $ace.InheritanceFlags | Should -Be $expectedInheritanceFlags
        $ace.PropagationFlags | Should -Be $expectedPropagationFlags
        $rights | Should -Be ($ace."$($providerName)Rights" -band $rights)
        $ace.AccessControlType | Should -Be ([Security.AccessControl.AccessControlType]$Type)
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

        $ExpectedRuleType = ('Security.AccessControl.{0}AccessRule' -f $ExpectedRuleType) -as [Type]
        $result = Grant-Permission -Identity $Identity -Permission $Permissions -Path $path -PassThru @optionalParams
        $result = $result | Select-Object -Last 1
        $result | Should -Not -BeNullOrEmpty
        $result.IdentityReference | Should -Be (Resolve-IdentityName $Identity)
        $result | Should -BeOfType $ExpectedRuleType
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
            $path = Join-Path -Path $script:testDirPath -ChildPath ([IO.Path]::GetRandomFileName())
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
}

Describe 'Grant-CPermission' {
    BeforeEach {
        $script:testDirPath = Join-Path -Path $TestDrive -ChildPath $script:testNum
        New-Item -Path $script:testDirPath -ItemType 'Directory'
    }

    AfterEach {
        $script:testNum += 1
    }

    It 'when changing permissions on a file' {
        $file = New-TestFile
        $identity = 'BUILTIN\Administrators'
        $permissions = 'Read','Write'

        Invoke-GrantPermissions -Identity $identity -Permissions $permissions -Path $file
    }

    It 'when changing permissions on a directory' {
        $dir = New-TestContainer -FileSystem
        $identity = 'BUILTIN\Administrators'
        $permissions = 'Read','Write'

        Invoke-GrantPermissions -Identity $identity -Permissions $permissions -Path $dir
    }

    It 'when changing permissions on registry key' {
        $regKey = New-TestContainer -Registry

        Invoke-GrantPermissions -Identity 'BUILTIN\Administrators' -Permission 'ReadKey' -Path $regKey -ExpectedRuleType 'Registry'
    }

    It 'when passing an invalid permission' {
        $path = New-TestFile
        $failed = $false
        $error.Clear()
        $result = Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'BlahBlahBlah' -Path $path -PassThru -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $error.Count | Should -Be 2
    }

    It 'when clearing existing permissions' {
        $path = New-TestFile
        Invoke-GrantPermissions $user 'FullControl' -Path $path
        Invoke-GrantPermissions $user2 'FullControl' -Path $path

        $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $path -Clear -PassThru
        $result | Should -Not -BeNullOrEmpty
        $result.Path | Should -Be $Path

        $acl = Get-Acl -Path $path

        $rules = $acl.Access |
                    Where-Object { -not $_.IsInherited }
        $rules | Should -Not -BeNullOrEmpty
        $rules.IdentityReference.Value | Should -Be 'Everyone'
    }

    It 'when there are no existing permissions to clear' {
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
        $result | Should -Not -BeNullOrEmpty
        $result.IdentityReference | Should -Be 'Everyone'

        $error.Count | Should -Be 0

        $acl = Get-Acl -Path $path
        $rules = $acl.Access | Where-Object { -not $_.IsInherited }
        $rules | Should -Not -BeNullOrEmpty
        ($rules.IdentityReference.Value -like 'Everyone') | Should -BeTrue
    }

    $containerFlags = @(
        'Container',
        'ContainerAndSubContainers',
        'ContainerAndLeaves',
        'SubContainersAndLeaves',
        'ContainerAndChildContainers',
        'ContainerAndChildLeaves',
        'ContainerAndChildContainersAndChildLeaves',
        'ContainerAndSubContainersAndLeaves',
        'SubContainers',
        'Leaves',
        'ChildContainers',
        'ChildLeaves',
        'ChildContainersAndChildLeaves'
    )

    It 'when setting <_> inheritance flags' -TestCases $containerFlags {
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

        $script:map = @{
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

        $containerInheritanceFlag = $_
        $containerPath = New-TestContainer -FileSystem

        $childLeafPath = Join-Path $containerPath 'ChildLeaf'
        $null = New-Item $childLeafPath -ItemType File

        $childContainerPath = Join-Path $containerPath 'ChildContainer'
        $null = New-Item $childContainerPath -ItemType Directory

        $grandchildContainerPath = Join-Path $childContainerPath 'GrandchildContainer'
        $null = New-Item $grandchildContainerPath -ItemType Directory

        $grandchildLeafPath = Join-Path $childContainerPath 'GrandchildLeaf'
        $null = New-Item $grandchildLeafPath -ItemType File

        $flags = $script:map[$containerInheritanceFlag]
        Invoke-GrantPermissions -Identity $user -Path $containerPath -Permission Read -ApplyTo $containerInheritanceFlag
    }

    It 'when setting inheritance flags on a file' {
        $path = New-TestFile
        $warnings = @()
        $result = Grant-CPermission -Identity $user -Permission Read -Path $path -ApplyTo Container -WarningAction SilentlyContinue -WarningVariable 'warnings'
        $warnings | Should -Not -BeNullOrEmpty
        ($warnings[0] -like '*Can''t apply inheritance/propagation rules to a leaf*') | Should -BeTrue
    }

    It 'when a user already has a different permission' {
        $containerPath = New-TestContainer -FileSystem
        Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath -ApplyTo Container
        Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath -Apply Container
    }

    It 'when a user already has the permissions' {
        $containerPath = New-TestContainer -FileSystem

        Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath

        Mock -CommandName 'Set-Acl' -Verifiable -ModuleName 'Carbon'

        Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath
        Assert-MockCalled -CommandName 'Set-Acl' -Times 0 -ModuleName 'Carbon'
    }

    It 'when changing inheritance flags' {
        $containerPath = New-TestContainer -FileSystem
        Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves
        Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath -ApplyTo Container
    }

    It 'when forcing a permission change and the user already has the permissions' {
        $containerPath = New-TestContainer -FileSystem

        Invoke-GrantPermissions -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves

        Mock -CommandName 'Set-Acl' -Verifiable -ModuleName 'Carbon'

        Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -Apply ContainerAndLeaves -Force

        Assert-MockCalled -CommandName 'Set-Acl' -Times 1 -Exactly -ModuleName 'Carbon'
    }

    It 'when an item is hidden' {
        $Global:Error.Clear()

        $path = New-TestFile
        $item = Get-Item -Path $path
        $item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden

        $result = Invoke-GrantPermissions -Identity $user -Permission Read -Path $path
        $Global:Error.Count | Should -Be 0
    }

    It 'when the path does not exist' {
        $Global:Error.Clear()

        $result = Grant-Permission -Identity $user -Permission Read -Path 'C:\I\Do\Not\Exist' -PassThru -ErrorAction SilentlyContinue
        $result | Should -BeNullOrEmpty
        $Global:Error.Count | Should -BeGreaterThan 0
        $Global:Error[0] | Should -Match 'Cannot find path'
    }

    It 'when clearing a permission that already exists on a file' {
        $Global:Error.Clear()
        $path = New-TestFile
        Invoke-GrantPermissions -Identity $user -Permission Read -Path $Path
        Invoke-GrantPermissions -Identity $user -Permission Read -Path $Path -Clear
        $Global:Error | Should -BeNullOrEmpty
    }

    It 'when clearing permissions that already exist on a directory' {
        $Global:Error.Clear()

        $containerPath = New-TestContainer -FileSystem

        Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath
        Invoke-GrantPermissions -Identity $user -Permission Read -Path $containerPath -Clear

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'when clearing permissions that already exist on a registry key' {
        $Global:Error.Clear()
        $regContainerPath = New-TestContainer -Registry
        Invoke-GrantPermissions -Identity $user -Permission QueryValues -Path $regContainerPath -ExpectedRuleType 'Registry'
        Invoke-GrantPermissions -Identity $user -Permission QueryValues -Path $regContainerPath -ExpectedRuleType 'Registry' -Clear

        $Global:Error | Should -BeNullOrEmpty
    }

    It 'when clearing permissions on the file system and verbose preference is continue' {
        $containerPath = New-TestContainer -FileSystem

        $result = Grant-Permission -Identity $user -Permission Read -Path $containerPath -Verbose 4>&1
        $result | Should -BeOfType 'Management.Automation.VerboseRecord'

        $result = Grant-Permission -Identity $user2 -Permission Read -Path $containerPath -Clear -Verbose 4>&1
        $result | Should -Not -BeNullOrEmpty
        ($result.Count -ge 2) | Should -BeTrue
        for( $idx = 0; $idx -lt $result.Count - 1; ++$idx )
        {
            $result[$idx] | Should -BeOfType 'Management.Automation.VerboseRecord'
            ($result[$idx].Message -like ('*{0}* -> ' -f $user)) | Should -BeTrue
        }
    }

    It 'when clearing permissions on a registry key and verbose preference is continue' {
        $regContainerPath = New-TestContainer -Registry
        $result = Grant-Permission -Identity $user -Permission QueryValues -Path $regContainerPath -Verbose 4>&1
        $result | Should -BeOfType 'Management.Automation.VerboseRecord'

        $result = Grant-Permission -Identity $user2 -Permission QueryValues -Path $regContainerPath -Clear -Verbose 4>&1
        $result | Should -Not -BeNullOrEmpty
        $result.Count | Should -Be 2
        $result[0] | Should -BeOfType 'Management.Automation.VerboseRecord'
        ($result[0].Message -like ('*QueryValues -> ' -f $user)) | Should -BeTrue
        $result[1] | Should -BeOfType 'Management.Automation.VerboseRecord'
        ($result[1].Message -like ('* -> QueryValues' -f $user)) | Should -BeTrue
    }

    It 'when setting permissions on a private key in the <_> location' -TestCases @('LocalMachine', 'CurrentUser') {
        $location = $_
        $cert = Install-Certificate -Path $privateKeyPath -StoreLocation $location -StoreName My -NoWarn
        try
        {
            $certPath = Join-Path -Path ('cert:\{0}\My' -f $location) -ChildPath $cert.Thumbprint
            $expectedRuleType = 'CryptoKey'
            $readPermission = 'GenericRead'
            $writePermission = 'GenericWrite'

            # CryptoKey does not exist in .NET standard/core so we will have to use FileSystem instead
            if( -not (Invoke-CPrivateCommand -Name 'Test-CCryptoKeyAvailable') )
            {
                $expectedRuleType = 'FileSystem'
                $readPermission = 'Read'
                $writePermission = 'Write'
            }

            $cert | Should -Not -BeNullOrEmpty

            # Context 'adds permissions' {
            Invoke-GrantPermissions -Path $certPath -Identity $user -Permission $writePermission -ExpectedRuleType $expectedRuleType -ExpectedPermission 'GenericRead','GenericAll'

            # Context 'changes permissions' {
            Invoke-GrantPermissions -Path $certPath -Identity $user -Permission $readPermission -ExpectedRuleType $expectedRuleType

            # Context 'clearing others'' permissions' {
            Invoke-GrantPermissions -Path $certPath -Identity $user2 -Permission $readPermission -ExpectedRuleType $expectedRuleType -Clear
            (Test-Permission -Path $certPath -Identity $user -Permission $readPermission) | Should -BeFalse

            # Context 'clearing others'' permissions when permissions getting set haven''t changed' {
            Invoke-GrantPermissions -Path $certPath -Identity $user -Permission $readPermission -ExpectedRuleType $expectedRuleType
            Invoke-GrantPermissions -Path $certPath -Identity $user2 -Permission $readPermission -ExpectedRuleType $expectedRuleType -Clear
            (Test-Permission -Path $certPath -Identity $user -Permission $readPermission) | Should -BeFalse

            # Context 'running with -WhatIf switch' {
            Grant-Permission -Path $certPath -Identity $user2 -Permission $writePermission -WhatIf
            Test-Permission -Path $certPath -Identity $user2 -Permission $readPermission -Exact | Should -BeTrue
            Test-Permission -Path $certPath -Identity $user2 -Permission $writePermission -Exact | Should -BeFalse

            # Context 'creating a deny rule' {
            Invoke-GrantPermissions -Path $certPath -Identity $user -Permission $readPermission -Type 'Deny' -ExpectedRuleType $expectedRuleType


            # CryptoKey does not exist in .NET standard/core
            if( (Invoke-CPrivateCommand -Name 'Test-CCryptoKeyAvailable') )
            {
                Mock -CommandName 'Set-CryptoKeySecurity' -Verifiable -ModuleName 'Carbon'

                # Context 'permissions exist' {
                # Now, check that permissions don't get re-applied.
                Grant-Permission -Path $certPath -Identity $user2 -Permission $readPermission
                Assert-MockCalled -CommandName 'Set-CryptoKeySecurity' -ModuleName 'Carbon' -Times 0

                # Context 'permissions exist but forcing the change' {
                Grant-Permission -Path $certPath -Identity $user2 -Permission $readPermission -Force
                Assert-MockCalled -CommandName 'Set-CryptoKeySecurity' -ModuleName 'Carbon' -Times 1 -Exactly
            }
        }
        finally
        {
            Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation $location -StoreName My -NoWarn
        }
    }

    It 'when setting Deny rule on file system' {
        $filePath = New-TestFile
        Invoke-GrantPermissions -Identity $user -Permissions 'Write' -Path $filePath -Type 'Deny'
    }

    It 'when setting Deny rule on registry' {
        $path = New-TestContainer -Registry
        Invoke-GrantPermissions -Identity $user -Permissions 'Write' -Path $path -Type 'Deny' -ExpectedRuleType 'Registry'
    }

    It 'when granting multiple different rules to a user on the file system' {
        $dirPath = New-TestContainer -FileSystem
        Grant-CPermission -Path $dirPath -Identity $user -Permission 'Read' -ApplyTo ContainerAndSubContainersAndLeaves -Append
        Grant-CPermission -Path $dirPath -Identity $user -Permission 'Write' -ApplyTo ContainerAndLeaves -Append
        $perm = Get-CPermission -Path $dirPath -Identity $user
            $perm | Should -HaveCount 2
    }
}
