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

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon -Resolve) -Force
    $Path = @([IO.Path]::GetTempFileName())[0]
}

function TearDown
{
    if( Test-Path $Path )
    {
        Remove-Item $Path
    }
}

function Invoke-GrantPermissions($Identity, $Permissions)
{
    Grant-Permissions -Identity $Identity -Permission $Permissions -Path $Path.ToString()
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
    
    Write-Host $SCRIPT:Dir
    Invoke-GrantPermissions -Identity $identity -Permissions $permissions
    Assert-Permissions $identity $permissions
}

function Test-ShouldGrantPermissionsOnRegistryKey
{
    $regKey = 'hkcu:\TestGrantPermissions'
    New-Item $regKey
    
    try
    {
        Grant-Permissions -Identity 'BUILTIN\Administrators' -Permissions 'ReadKey' -Path $regKey
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
    try
    {
        Invoke-GrantPermissions 'BUILTIN\Administrators' 'BlahBlahBlah'
    }
    catch
    {
        $failed = $_ -like 'Invalid FileSystemRights: BlahBlahBlah.  Must be one of ListDirectory*'
    }
    
    Assert-True $failed "Didn't fail to set permissions with a bad permission."
}

function Test-ShouldClearExistingPermissions
{
    Invoke-GrantPermissions 'Administrators' 'FullControl'
    
    Grant-Permissions -Identity 'Everyone' -Permissions 'Read','Write' -Path $Path.ToSTring() -Clear
    
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
    Grant-Permissions -Identity 'Everyone' -Permissions 'Read','Write' -Path $Path.ToSTring() -Clear -ErrorAction SilentlyContinue
    Assert-Equal 0 $error.Count
    $acl = Get-Acl -Path $Path.ToString()
    $rules = $acl.Access | Where-Object { -not $_.IsInherited }
    Assert-NotNull $rules
    Assert-Like $rules.IdentityReference.Value 'Everyone'
}

function Assert-Permissions($identity, $permissions, $path = $Path)
{
    $providerName = (Get-PSDrive (Split-Path -Qualifier (Resolve-Path $path)).Trim(':')).Provider.Name
    
    $rights = 0
    foreach( $permission in $permissions )
    {
        $rights = $rights -bor ($permission -as "Security.AccessControl.$($providerName)Rights")
    }
    
    $acl = Get-Acl $path
    Assert-NotNull $acl "Didn't get ACLs for $path."
    
    $hasPermission = $false
    foreach( $accessRights in $acl.Access )
    {
        $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
        if( Test-Path $path -PathType Container )
        {
            $expectedInheritanceFlags = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                                        [Security.AccessControl.InheritanceFlags]::ObjectInherit
        }
        $hasExpectedInheritance = ($accessRights.InheritanceFlags -band $expectedInheritanceFlags) -eq $expectedInheritanceFlags
        $hasExpectedRights = ($accessRights."$($providerName)Rights" -band $rights) -eq $rights
        $isExpectedIdentity = ($accessRights.IdentityReference -eq $identity )
        
        if( $hasExpectedInheritance -and $hasExpectedRights -and $isExpectedIdentity )
        {
            $hasPermission = $true
            break
        }
    }
    
    Assert-True $hasPermission "$identity doesn't have $permissions on $path."
}

