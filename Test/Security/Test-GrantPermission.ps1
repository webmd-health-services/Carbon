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

$Path = $null
$user = 'CarbonGrantPerms'
$user2 = 'CarbonGrantPerms2'
$containerPath = $null
$regContainerPath = $null
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\CarbonTestPrivateKey.pfx' -Resolve

function Start-TestFixture
{
    & (Join-Path -Path $TestDir -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
    Install-User -Credential (New-Credential -Username $user -Password 'a1b2c3d4!') -Description 'User for Carbon Grant-Permission tests.'
    Install-User -Credential (New-Credential -Username $user2 -Password 'a1b2c3d4!') -Description 'User for Carbon Grant-Permission tests.'
}

function Start-Test
{
    $containerPath = New-TempDir -Prefix 'Carbon_Test-GrantPermisssion'
    $Path = Join-Path -Path $containerPath -ChildPath ([IO.Path]::GetRandomFileName())
    $null = New-Item -ItemType 'File' -Path $Path

    $regContainerPath = 'hkcu:\CarbonTestGrantPermission{0}' -f ([IO.Path]::GetRandomFileName())
    New-Item -Path $regContainerPath
}

function Stop-Test
{
    if( Test-Path $containerPath )
    {
        Remove-Item $containerPath -Recurse -Force
    }

    if( Test-Path $regContainerPath )
    {
        Remove-Item $regContainerPath -Recurse -Force
    }
}

function Invoke-GrantPermissions($Identity, $Permissions, $Path)
{
    $result = Grant-Permission -Identity $Identity -Permission $Permissions -Path $Path.ToString() -PassThru
    Assert-NotNull $result
    Assert-Equal (Resolve-IdentityName $Identity) $result.IdentityReference
    Assert-Is $result ([Security.AccessControl.FileSystemAccessRule])
}

function Test-ShouldGrantPermissionOnFile
{
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions -Path $Path
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionOnDirectory
{
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions -Path $containerPath
    Assert-Permissions $identity $permissions -path $containerPath
}

function Test-ShouldGrantPermissionsOnRegistryKey
{
    $regKey = 'hkcu:\TestGrantPermissions'
    New-Item $regKey
    
    try
    {
        $result = Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'ReadKey' -Path $regKey -PassThru
        Assert-NotNull $result
        Assert-Is $result ([Security.AccessControl.RegistryAccessRule]) 
        Assert-Equal $regKey $result.Path
        Assert-Permissions 'BUILTIN\Administrators' -Permissions 'ReadKey' -Path $regKey
    }
    finally
    {
        Remove-Item $regKey
    }
}

function Test-ShouldFailIfIncorrectPermissions
{
    $failed = $false
    $error.Clear()
    $result = Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'BlahBlahBlah' -Path $Path.ToString() -PassThru -ErrorAction SilentlyContinue
    Assert-Null $result
    Assert-Equal 2 $error.Count
}

function Test-ShouldClearExistingPermissions
{
    Invoke-GrantPermissions $user 'FullControl' -Path $Path
    Invoke-GrantPermissions $user2 'FullControl' -Path $Path
    
    $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $Path.ToString() -Clear -PassThru
    Assert-NotNull $result
    Assert-Equal $Path $result.Path
    
    $acl = Get-Acl -Path $Path.ToString()
    
    $rules = $acl.Access |
                Where-Object { -not $_.IsInherited }
    Assert-NotNull $rules
    Assert-Equal 'Everyone' $rules.IdentityReference.Value
}

function Test-ShouldHandleNoPermissionsToClear
{
    $acl = Get-Acl -Path $Path.ToSTring()
    $rules = $acl.Access | 
                Where-Object { -not $_.IsInherited }
    if( $rules )
    {
        $rules |
            ForEach-Object { $acl.REmoveAccessRule( $_ ) }
        Set-Acl -Path $Path.ToString() -AclObject $acl
    }
    
    $error.Clear()
    $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $Path.ToSTring() -Clear -PassThru -ErrorAction SilentlyContinue
    Assert-NotNull $result
    Assert-Equal 'Everyone' $result.IdentityReference
    Assert-Equal 0 $error.Count
    $acl = Get-Acl -Path $Path.ToString()
    $rules = $acl.Access | Where-Object { -not $_.IsInherited }
    Assert-NotNull $rules
    Assert-Like $rules.IdentityReference.Value 'Everyone'
}

function Test-ShouldSetInheritanceFlags
{
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

    if( (Test-Path -Path $containerPath -PathType Container) )
    {
        Remove-Item -Recurse -Path $containerPath
    }
    
    $map.Keys |
        ForEach-Object {
            try
            {
                $containerInheritanceFlag = $_
                $containerPath = 'Carbon-Test-GrantPermissions-{0}-{1}' -f ($containerInheritanceFlag,[IO.Path]::GetRandomFileName())
                $containerPath = Join-Path $env:Temp $containerPath
                
                $null = New-Item $containerPath -ItemType Directory
                
                $childLeafPath = Join-Path $containerPath 'ChildLeaf'
                $null = New-Item $childLeafPath -ItemType File
                
                $childContainerPath = Join-Path $containerPath 'ChildContainer'
                $null = New-Item $childContainerPath -ItemType Directory
                
                $grandchildContainerPath = Join-Path $childContainerPath 'GrandchildContainer'
                $null = New-Item $grandchildContainerPath -ItemType Directory
                
                $grandchildLeafPath = Join-Path $childContainerPath 'GrandchildLeaf'
                $null = New-Item $grandchildLeafPath -ItemType File

                $flags = $map[$containerInheritanceFlag]
                $result = Grant-Permission -Identity $user -Path $containerPath -Permission Read -ApplyTo $containerInheritanceFlag -PassThru
                Assert-NotNull $result
                Assert-Equal $containerPath $result.Path
                Assert-InheritanceFlags $containerInheritanceFlag $flags.InheritanceFlags $flags.PropagationFlags
            }
            finally
            {
                Remove-Item $containerPath -Recurse
            }                
        }
}

function Test-ShouldWriteWarningWhenInheritanceFlagsGivenOnLeaf
{
    $warnings = @()
    $result = Grant-Permission -Identity $user -Permission Read -Path $Path -ApplyTo Container -PassThru -WarningAction SilentlyContinue -WarningVariable 'warnings'
    Assert-NotNull $result
    Assert-Equal $Path $result.Path
    Assert-NotNull $warnings
    Assert-Like $warnings[0] '*Can''t apply inheritance/propagation rules to a leaf*' 
}

function Test-ShouldChangePermissions
{
    $rule = Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo Container -PassThru
    Assert-NotNull $rule
    Assert-True (Test-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo Container -Exact)
    $rule = Grant-Permission -Identity $user -Permission Read -Path $containerPath -Apply Container -PassThru
    Assert-NotNull $rule
    Assert-True (Test-Permission -Identity $user -Permission Read -Path $containerPath -ApplyTo Container -Exact)
}

function Test-ShouldNotReapplyPermissionsAlreadyGranted
{
    $rule = Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -PassThru
    Assert-NotNull $rule
    Assert-True (Test-Permission -Identity $user -Permission FullControl -Path $containerPath -Exact)
    $rule = Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -PassThru
    Assert-NotNull $rule
    Assert-True (Test-Permission -Identity $user -Permission FullControl -Path $containerPath -Exact)
}

function Test-ShouldChangeInheritanceFlags
{
    $result = Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves
    Assert-Null $result
    Assert-True (Test-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves -Exact)
    $result = Grant-Permission -Identity $user -Permission Read -Path $containerPath -Apply Container
    Assert-Null $result
    Assert-True (Test-Permission -Identity $user -Permission Read -Path $containerPath -ApplyTo Container -Exact)
}

function Test-ShouldReapplySamePermissions
{
    $result = Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves
    Assert-Null $result
    Assert-True (Test-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves -Exact)
    $result = Grant-Permission -Identity $user -Permission FullControl -Path $containerPath -Apply ContainerAndLeaves -Force
    Assert-True (Test-Permission -Identity $user -Permission FullControl -Path $containerPath -ApplyTo ContainerAndLeaves -Exact)
    Assert-Null $result
}

function Test-ShouldGrantPermissionOnHiddenItem
{
    $item = Get-Item -Path $Path
    $item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden

    $result = Grant-Permission -Identity $user -Permission Read -Path $Path
    Assert-Null $result
    Assert-Permissions $user 'Read' $Path
    Assert-NoError
}

function Test-ShouldHandleNOnExistentPath
{
    $result = Grant-Permission -Identity $user -Permission Read -Path 'C:\I\Do\Not\Exist' -PassThru -ErrorAction SilentlyContinue
    Assert-Null $result
    Assert-Error -Last 'Cannot find path'
}

function Test-ShouldNotClearPermissionGettingSetOnFile
{
    $result = Grant-Permission -Identity $user -Permission Read -Path $Path -PassThru
    Assert-NotNull $result
    Assert-Is $result 'Security.AccessControl.FileSystemAccessRule'
    $result = Grant-Permission -Identity $user -Permission Read -Path $Path -Clear -PassThru
    Assert-NotNull $result
}

function Test-ShouldNotClearPermissionGettingSetOnDirectory
{
    $result = Grant-Permission -Identity $user -Permission Read -Path $containerPath -PassThru
    Assert-NotNull $result
    Assert-Is $result 'Security.AccessControl.FileSystemAccessRule'
    $result = Grant-Permission -Identity $user -Permission Read -Path $containerPath -Clear -Pass
    Assert-NOtNull $result
    Assert-Null ($result | Where-Object { $_.IdentityReference.Value -eq $user })
}

function Test-ShouldNotClearPermissionGettingSetOnRegKey
{
    $result = Grant-Permission -Identity $user -Permission QueryValues -Path $regContainerPath -PassThru
    Assert-NotNull $result
    Assert-Is $result 'Security.AccessControl.RegistryAccessRule'
    $result = Grant-Permission -Identity $user -Permission QueryValues -Path $regContainerPath -Clear -PassThru
    Assert-NotNull $result
}

function Test-ShouldWriteVerboseMessageWhenClearingRuleOnFileSystem
{
    $result = Grant-Permission -Identity $user -Permission Read -Path $containerPath -PassThru -Verbose 4>&1
    Assert-NotNull $result
    Assert-Equal 2 $result.Count
    Assert-Is $result[0] 'Management.Automation.VerboseRecord'
    Assert-Is $result[1] 'Security.AccessControl.FileSystemAccessRule'
    [object[]]$result = Grant-Permission -Identity $user2 -Permission Read -Path $containerPath -Clear -PassThru -Verbose 4>&1
    Assert-NotNull $result
    Assert-True ($result.Count -ge 2)
    for( $idx = 0; $idx -lt $result.Count - 1; ++$idx )
    {
        Assert-Is $result[$idx] 'Management.Automation.VerboseRecord'
        Assert-Like $result[$idx].Message ('*{0}* -> ' -f $user)
    }
    Assert-Is $result[-1] 'Security.AccessControl.FileSystemAccessRule'
    Assert-Equal (Resolve-IdentityName $user2) $result[-1].IdentityReference.Value
}

function Test-ShouldWriteVerboseMessageWhenClearingRuleOnRegKey
{
    $result = Grant-Permission -Identity $user -Permission QueryValues -Path $regContainerPath -PassThru -Verbose 4>&1
    Assert-NotNull $result
    Assert-Equal 2 $result.Count
    Assert-Is $result[0] 'Management.Automation.VerboseRecord'
    Assert-Is $result[1] 'Security.AccessControl.RegistryAccessRule'
    [object[]]$result = Grant-Permission -Identity $user2 -Permission QueryValues -Path $regContainerPath -Clear -PassThru -Verbose 4>&1
    Assert-NotNull $result
    Assert-Equal 3 $result.Count
    Assert-Is $result[0] 'Management.Automation.VerboseRecord'
    Assert-Like $result[0].Message ('*QueryValues -> ' -f $user)
    Assert-Is $result[1] 'Management.Automation.VerboseRecord'
    Assert-Like $result[1].Message ('* -> QueryValues' -f $user)
    Assert-Is $result[2] 'Security.AccessControl.RegistryAccessRule'
    Assert-Equal (Resolve-IdentityName $user2) $result[2].IdentityReference.Value
}

function Test-ShouldGrantPermissionOnPrivateKey
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
    try
    {
        Assert-NotNull $cert
        $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead' -PassThru
        Assert-NoError
        Assert-Is $result ([Security.AccessControl.CryptoKeyAccessRule])
        Assert-Equal $certPath $result.Path
        Assert-Permissions $user 'GenericRead' $certPath

        # Now, check that permissions don't get re-applied.
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead' -PassThru
        Assert-NoError
        Assert-Is $result ([Security.AccessControl.CryptoKeyAccessRule])
        Assert-Permissions $user 'GenericRead' $certPath

        # Now, test that you can force the change
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead' -Force -PassThru
        Assert-NoError
        Assert-Is $result ([Security.AccessControl.CryptoKeyAccessRule])
        Assert-Equal $certPath $result.Path
        Assert-Permissions $user 'GenericRead' $certPath

        # Now, check that permissions get updated.
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericWrite' -PassThru
        Assert-NoError
        Assert-NotNull $result
        Assert-Is $result ([Security.AccessControl.CryptoKeyAccessRule])
        Assert-Equal $certPath $result.Path
        Assert-Permissions $user 'GenericAll','GenericRead' $certPath
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My
    }
}

function Test-ShouldSetPermissionsWhenSameAndClearingOtherPermissions
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
    try
    {
        Assert-NotNull $cert
        $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead'
        Assert-Null $result
        Assert-Permissions $user 'GenericRead' $certPath
        $me = '{0}\{1}' -f $env:USERDOMAIN,$env:USERNAME
        $result = Grant-Permission -Path $certPath -Identity $me -Permission 'GenericRead'
        Assert-Null $result
        Assert-Permissions $me 'GenericRead' $certPath
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead' -Clear -PassThru -Verbose
        Assert-NoError
        Assert-Is $result ([Security.AccessControl.CryptoKeyAccessRule])
        Assert-Equal $certPath $result.Path
        Assert-Permissions $user 'GenericRead' $certPath
        Assert-False (Test-Permission -Path $certPath -Identity $me -Permission 'GenericRead')
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My
    }
}

function Test-ShouldClearPermissionsOnPrivateKey
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
    try
    {
        Assert-NotNull $cert
        $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead'
        Assert-Null $result
        Assert-NotNull (Get-Permission -Path $certPath -Identity $user)

        $me = '{0}\{1}' -f $env:USERDOMAIN,$env:USERNAME
        $result = Grant-Permission -Path $certPath -Identity $me -Permission 'FullControl'
        Assert-Null $result
        Assert-NotNull (Get-Permission -Path $certPath -Identity $me)

        $result = Grant-Permission -Path $certPath -Identity $me -Permission 'FullControl' -Clear -Verbose
        Assert-Null $result
        Assert-Null (Get-Permission -Path $certPath -Identity $user)
        Assert-NotNull (Get-Permission -Path $certPath -Identity $me)
        Assert-NoError
        Assert-Permissions $me 'GenericRead' $certPath
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My
    }
}

function Test-ShouldSetPermissionsOnUserPrivateKey
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation CurrentUser -StoreName My
    try
    {
        $certPath = Join-Path -Path 'cert:\CurrentUser\My' -ChildPath $cert.Thumbprint
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead'
        Assert-Null $result
        Assert-NoError
        Assert-Permissions $user 'GenericRead' $certPath
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation CurrentUser -StoreName My
    }
}

function Test-ShouldSupportWhatIfOnPrivateKey
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
    try
    {
        $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
        $result = Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -WhatIf
        Assert-Null $result
        Assert-NoError
        Assert-Null (Get-Permission -Path $certPath -Identity $user)
    }
    finally
    {
        Uninstall-Certificate -Thumbprint $cert.Thumbprint -StoreLocation LocalMachine -StoreName My
    }
}

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
                
    Assert-NotNull $ace $ContainerInheritanceFlags
    $expectedRights = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Synchronize
    Assert-Equal $expectedRights $ace.FileSystemRights ('{0} file system rights' -f $ContainerInheritanceFlags)
    Assert-Equal $InheritanceFlags $ace.InheritanceFlags ('{0} inheritance flags' -f $ContainerInheritanceFlags)
    Assert-Equal $PropagationFlags $ace.PropagationFlags ('{0} propagation flags' -f $ContainerInheritanceFlags)
}

function Assert-Permissions($identity, $permissions, $path = $Path)
{
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
    Assert-NotNull $ace "Didn't get access control rule for $path."
    
    $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
    if( Test-Path $path -PathType Container )
    {
        $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                                    [Security.AccessControl.InheritanceFlags]::ObjectInherit
    }
    Assert-Equal $expectedInheritanceFlags $ace.InheritanceFlags
    Assert-Equal ([Security.AccessControl.PropagationFlags]::None) $ace.PropagationFlags
    Assert-Equal ($ace."$($providerName)Rights" -band $rights) $rights
}

