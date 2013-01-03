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

function Setup
{
    & (Join-Path $TestDir ..\..\Carbon\Import-Carbon.ps1 -Resolve)
    
    Install-User -Username $user -Password 'a1b2c3d4!' -Description 'User for Carbon Grant-Permission tests.'
    
    $Path = @([IO.Path]::GetTempFileName())[0]
}

function TearDown
{
    if( Test-Path $Path )
    {
        Remove-Item $Path
    }
    
    Remove-Module Carbon
}

function Invoke-GrantPermission($Identity, $Permissions)
{
    Grant-Permission -Identity $Identity -Permission $Permissions -Path $Path.ToString()
}

function Test-ShouldGrantPermissionOnFile
{
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Invoke-GrantPermission -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionOnDirectory
{
    $Path = New-TempDir
    
    $identity = 'BUILTIN\Administrators'
    $permissions = 'Read','Write'
    
    Write-Host $SCRIPT:Dir
    Invoke-GrantPermission -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionsOnRegistryKey
{
    $regKey = 'hkcu:\TestGrantPermission'
    New-Item $regKey
    
    try
    {
        Grant-Permission -Identity 'BUILTIN\Administrators' -Permissions 'ReadKey' -Path $regKey
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
    Grant-Permission -Identity 'BUILTIN\Administrators' -Permission 'BlahBlahBlah' -Path $Path.ToString() -ErrorAction SilentlyContinue
    Assert-Equal 1 $error.Count
}

function Test-ShouldClearExistingPermissions
{
    Invoke-GrantPermission 'Administrators' 'FullControl'
    
    Grant-Permission -Identity 'Everyone' -Permissions 'Read','Write' -Path $Path.ToSTring() -Clear
    
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
    Grant-Permission -Identity 'Everyone' -Permissions 'Read','Write' -Path $Path.ToSTring() -Clear -ErrorAction SilentlyContinue
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
                $containerPath = 'Carbon-Test-GrantPermission-{0}-{1}' -f ($containerInheritanceFlag,[IO.Path]::GetRandomFileName())
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
                #Write-Host ('{0}: {1}     {2}' -f $_,$flags.InheritanceFlags,$flags.PropagationFlags)
                Grant-Permission -Identity $user -Path $containerPath -Permissions Read -ApplyTo $containerInheritanceFlag
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
    Grant-Permission -Identity $user -Permissions Read -Path $Path -ApplyTo Container
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

    #Write-Host ('{0}: {1}     {2}' -f $ContainerInheritanceFlags,$InheritanceFlags,$PropagationFlags)
    $ace = Get-Permissions $containerPath -Identity $user
                
    Assert-NotNull $ace $ContainerInheritanceFlags
    $expectedRights = [Security.AccessControl.FileSystemRights]::Read -bor [Security.AccessControl.FileSystemRights]::Synchronize
    Assert-Equal $expectedRights $ace.FileSystemRights ('{0} file system rights' -f $ContainerInheritanceFlags)
    Assert-Equal $InheritanceFlags $ace.InheritanceFlags ('{0} inheritance flags' -f $ContainerInheritanceFlags)
    Assert-Equal $PropagationFlags $ace.PropagationFlags ('{0} propagation flags' -f $ContainerInheritanceFlags)
}

function Assert-Permissions($identity, $permissions, $path = $Path)
{
    $providerName = (Get-PSDrive (Split-Path -Qualifier (Resolve-Path $path)).Trim(':')).Provider.Name
    
    $rights = 0
    foreach( $permission in $permissions )
    {
        $rights = $rights -bor ($permission -as "Security.AccessControl.$($providerName)Rights")
    }
    
    $ace = Get-Permissions -Path $path -Identity $identity
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

