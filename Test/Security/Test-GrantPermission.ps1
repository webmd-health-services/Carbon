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
$containerPath = $null
$privateKeyPath = Join-Path -Path $PSScriptRoot -ChildPath '..\Cryptography\CarbonTestPrivateKey.pfx' -Resolve

function Start-TestFixture
{
    & (Join-Path -Path $TestDir -ChildPath '..\Import-CarbonForTest.ps1' -Resolve)
}

function Start-Test
{
    Install-User -Username $user -Password 'a1b2c3d4!' -Description 'User for Carbon Grant-Permission tests.'
    
    $Path = @([IO.Path]::GetTempFileName())[0]
}

function Stop-Test
{
    if( Test-Path $Path )
    {
        Remove-Item $Path -Force
    }
}

function Invoke-GrantPermissions($Identity, $Permissions)
{
    $result = Grant-Permission -Identity $Identity -Permission $Permissions -Path $Path.ToString()
    Assert-Null $result
}

function Test-ShouldGrantPermissionOnFile
{
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionOnDirectory
{
    $Path = New-TempDir
    
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionsOnRegistryKey
{
    $regKey = 'hkcu:\TestGrantPermissions'
    New-Item $regKey
    
    try
    {
        $result = Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'ReadKey' -Path $regKey
        Assert-Null $result
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
    $result = Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'BlahBlahBlah' -Path $Path.ToString() -ErrorAction SilentlyContinue
    Assert-Null $result
    Assert-Equal 2 $error.Count
}

function Test-ShouldClearExistingPermissions
{
    Invoke-GrantPermissions 'Administrators' 'FullControl'
    Invoke-GrantPermissions 'SYSTEM' 'FullControl'
    
    $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $Path.ToSTring() -Clear
    Assert-Null $result
    
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
            ForEach-Object { $acl.REmoveAccessRule( $rule ) }
        Set-Acl -Path $Path.ToString() -AclObject $acl
    }
    
    $error.Clear()
    $result = Grant-Permission -Identity 'Everyone' -Permission 'Read','Write' -Path $Path.ToSTring() -Clear -ErrorAction SilentlyContinue
    Assert-Null $result
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
                $result = Grant-Permission -Identity $user -Path $containerPath -Permission Read -ApplyTo $containerInheritanceFlag
                Assert-Null $result
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
    $result = Grant-Permission -Identity $user -Permission Read -Path $Path -ApplyTo Container
    Assert-Null $result
}

function Test-ShouldGrantPermissionOnHiddenItem
{
    $item = Get-Item -Path $Path
    $item.Attributes = $item.Attributes -bor [IO.FileAttributes]::Hidden

    $result = Grant-Permission -Identity $user -Permission Read -Path $Path
    Assert-Permissions $user 'Read' $Path
    Assert-NoError
}

function Test-ShouldHandleNOnExistentPath
{
    $result = Grant-Permission -Identity $user -Permission Read -Path 'C:\I\Do\Not\Exist' -ErrorAction SilentlyContinue
    Assert-Null $result
    Assert-Error -Last 'Cannot find path'
}

function Test-ShouldGrantPermissionOnPrivateKey
{
    $cert = Install-Certificate -Path $privateKeyPath -StoreLocation LocalMachine -StoreName My
    try
    {
        Assert-NotNull $cert
        $certPath = Join-Path -Path 'cert:\LocalMachine\My' -ChildPath $cert.Thumbprint
        Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead'
        Assert-NoError
        Assert-Permissions $user 'GenericRead' $certPath
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
        Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead'
        Assert-NotNull (Get-Permission -Path $certPath -Identity $user)

        $me = '{0}\{1}' -f $env:USERDOMAIN,$env:USERNAME
        Grant-Permission -Path $certPath -Identity $me -Permission 'FullControl'
        Assert-NotNull (Get-Permission -Path $certPath -Identity $me)

        Grant-Permission -Path $certPath -Identity $me -Permission 'FullControl' -Clear -Verbose
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
        Grant-Permission -Path $certPath -Identity $user -Permission 'GenericRead'
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
        Grant-Permission -Path $certPath -Identity $user -Permission 'FullControl' -WhatIf
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

