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

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Initialize-CarbonDscResource.ps1' -Resolve)

function Get-TargetResource
{
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions.
        $Identity,
        
        [ValidateSet("CreateFiles","AppendData","CreateSubKey","EnumerateSubKeys","CreateLink","Delete","ChangePermissions","ExecuteFile","DeleteSubdirectoriesAndFiles","FullControl","GenericRead","GenericAll","GenericExecute","QueryValues","ReadAttributes","ReadData","ReadExtendedAttributes","GenericWrite","Notify","ReadPermissions","Read","ReadAndExecute","Modify","SetValue","ReadKey","TakeOwnership","WriteAttributes","Write","Synchronize","WriteData","WriteExtendedAttributes","WriteKey")]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,
        
        [ValidateSet('Container','SubContainers','ContainerAndSubContainers','Leaves','ContainerAndLeaves','SubContainersAndLeaves','ContainerAndSubContainersAndLeaves','ChildContainers','ContainerAndChildContainers','ChildLeaves','ContainerAndChildLeaves','ChildContainersAndChildLeaves','ContainerAndChildContainersAndChildLeaves')]
        [string]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo,

        [bool]
        $Append,
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $defaultState = @{
                        Path = $Path;
                        Identity = $Identity;
                        Permission = @();
                        ApplyTo = $null;
                        Ensure = 'Absent';
                    }

    $perms = Get-CPermission -Path $Path -Identity $Identity
    if( -not $perms )
    {
        return $defaultState
    }

    foreach( $perm in $perms )
    {
        $resource = $defaultState.Clone()
        [string[]]$resource.Permission = $perm | 
                                            Get-Member -Name '*Rights' -MemberType Property | 
                                            ForEach-Object { ($perm.($_.Name)).ToString() -split ',' } |
                                            ForEach-Object { $_.Trim() } | 
                                            Where-Object { $_ -ne 'Synchronize' }

        $resource.ApplyTo = ConvertTo-CContainerInheritanceFlags -InheritanceFlags $perm.InheritanceFlags -PropagationFlags $perm.PropagationFlags
        $resource.Ensure = 'Present'
        $resource
    }
}


function Set-TargetResource
{
    <#
    .SYNOPSIS
    DSC resource for managing permissions on files, directories, registry keys, or a certificate's private key.

    .DESCRIPTION
    The `Carbon_Permission` resource can grant or revoke permissions on a file, a directory, a registry key, or a certificate's private key.

    ### Granting Permission

    Permissions are granted when the `Ensure` property is set to `Present`.
    
    When granting permissions, you *must* supply a value for the `Permission` property. Valid values are:

     * CreateFiles
     * AppendData
     * CreateSubKey
     * EnumerateSubKeys
     * CreateLink
     * Delete
     * ChangePermissions
     * ExecuteFile
     * DeleteSubdirectoriesAndFiles
     * FullControl
     * GenericRead
     * GenericAll
     * GenericExecute
     * QueryValues
     * ReadAttributes
     * ReadData
     * ReadExtendedAttributes
     * GenericWrite
     * Notify
     * ReadPermissions
     * Read
     * ReadAndExecute
     * Modify
     * SetValue
     * ReadKey
     * TakeOwnership
     * WriteAttributes
     * Write
     * Synchronize
     * WriteData
     * WriteExtendedAttributes
     * WriteKey
    
    The `ApplyTo` property is only used when setting permissions on a directory or a registry key. Valid values are:

     * Container
     * SubContainers
     * ContainerAndSubContainers
     * Leaves
     * ContainerAndLeaves
     * SubContainersAndLeaves
     * ContainerAndSubContainersAndLeaves
     * ChildContainers
     * ContainerAndChildContainers
     * ChildLeaves
     * ContainerAndChildLeaves
     * ChildContainersAndChildLeaves
     * ContainerAndChildContainersAndChildLeaves

    Beginning in Carbon 2.7, you can add multiple permissions to an identity with the `Append` property. When set to true, it will add the permission instead of replacing an identity's current permissions. Note that DSC won't let you have two `Carbon_Permission` resources in your configuration where the identity and path properties are the same. Every `Carbon_Permission` resource must have unique identity and path properties. You may be able to work around this by using different values for the `Identity` property that resolve to the same identity, e.g. `Administrators` vs. `.\Administrators`.

    ### Revoking Permission
        
    Permissions are revoked when the `Ensure` property is set to `Absent`. *All* a user or group's permissions are revoked. You can't revoke part of a principal's access. If you want to revoke part of a principal's access, set the `Ensure` property to `Present` and the `Permissions` property to the list of properties you want the principal to have.

    `Carbon_Permission` is new in Carbon 2.0.

    .LINK
    Get-CPermission

    .LINK
    Grant-CPermission

    .LINK
    Revoke-CPermission

    .LINK
    Test-CPermission

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.cryptokeyrights.aspx
    
    .LINK
    http://msdn.microsoft.com/en-us/magazine/cc163885.aspx#S3    
    
    .EXAMPLE
    >
    Demonstrates how to grant permissions to an item on the file system.

        Carbon_Permission GrantPermission
        {
            Path = 'C:\Projects\Carbon';
            Identity = 'CarbonServiceUser';
            Permission = 'ReadAndExecute';
        }

    This will grant `ReadAndExecute` permission to the `CarbonServiceUser` on the `C:\Projects\Carbon` directory.

    .EXAMPLE
    >
    Demonstrates how to grant permissions to a registry key.

        Carbon_Permission GrantPermission
        {
            Path = 'hklm:\SOFTWARE\Carbon';
            Identity = 'CarbonServiceUser';
            Permission = 'ReadKey';
        }

    This will grant `ReadKey` permission to the `CarbonServiceUser` on the `C:\Projects\Carbon` directory.

    .EXAMPLE
    >
    Demonstrates how to grant permissions to a certificate's private key and how to grant multiple permissions.

        Carbon_Permission GrantPermission
        {
            Path = 'cert:\LocalMachine\My\1234567890ABCDEF1234567890ABCDEF12345678';
            Identity = 'CarbonServiceUser';
            Permission = 'GenericRead','ReadKey';
        }

    This will grant `GenericRead` and `ReadKey` permissions to the `CarbonServiceUser` on the `C:\Projects\Carbon` directory.

    .EXAMPLE
    >
    Demonstrates how to revoke permissions.

        Carbon_Permission GrantPermission
        {
            Path = 'C:\Projects\Carbon';
            Identity = 'CarbonServiceUser';
            Ensure = 'Absent';
        }

    This will revoke all of the `CarbonServiceUser` user's permissions on the `C:\Projects\Carbon`.


    .EXAMPLE
    >
    Demonstrates how to grant multiple permissions to the same local user:

        Carbon_Permission GrantReadAndExecute
        {
            Path = 'C:\Projects\Carbon';
            Identity = 'CarbonServiceUser';
            Permission = 'ReadAndExecute';
            ApplyTo = 'ContainerAndSubContainersAndLeaves';
            Append = $true;
            Ensure = 'Present';
        }

        Carbon_Permission GrantWrite
        {
            Path = 'C:\Projects\Carbon';
            Identity = '.\CarbonServiceUser';
            Permission = 'Write';
            ApplyTo = 'ContainerAndLeaves';
            Append = $true;
            Ensure = 'Present';
        }

    Demonstrates how grant to multiple permission to a user with the `Append` property. Note the `Append` property in both resources. If you omit one, permissions will always get ovewritten. Note the unique values on the `Identity` properties that resolve to the same user. This is due to the DSC requirement that a DSC resource must have unique key values and `Path` and `Identity` are the `Carbon_Permission` key values.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system, registry path, or certificate path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions.
        $Identity,
        
        [ValidateSet("CreateFiles","AppendData","CreateSubKey","EnumerateSubKeys","CreateLink","Delete","ChangePermissions","ExecuteFile","DeleteSubdirectoriesAndFiles","FullControl","GenericRead","GenericAll","GenericExecute","QueryValues","ReadAttributes","ReadData","ReadExtendedAttributes","GenericWrite","Notify","ReadPermissions","Read","ReadAndExecute","Modify","SetValue","ReadKey","TakeOwnership","WriteAttributes","Write","Synchronize","WriteData","WriteExtendedAttributes","WriteKey")]
        [string[]]
        # The permission: e.g. FullControl, Read, etc. Mandatory when granting permission. Valid values are `CreateFiles`, `AppendData`, `CreateSubKey`, `EnumerateSubKeys`, `CreateLink`, `Delete`, `ChangePermissions`, `ExecuteFile`, `DeleteSubdirectoriesAndFiles`, `FullControl`, `GenericRead`, `GenericAll`, `GenericExecute`, `QueryValues`, `ReadAttributes`, `ReadData`, `ReadExtendedAttributes`, `GenericWrite`, `Notify`, `ReadPermissions`, `Read`, `ReadAndExecute`, `Modify`, `SetValue`, `ReadKey`, `TakeOwnership`, `WriteAttributes`, `Write`, `Synchronize`, `WriteData`, `WriteExtendedAttributes`, `WriteKey`.
        $Permission,
        
        [ValidateSet('Container','SubContainers','ContainerAndSubContainers','Leaves','ContainerAndLeaves','SubContainersAndLeaves','ContainerAndSubContainersAndLeaves','ChildContainers','ContainerAndChildContainers','ChildLeaves','ContainerAndChildLeaves','ChildContainersAndChildLeaves','ContainerAndChildContainersAndChildLeaves')]
        [string]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is only used when `Path` is a directory or registry key. Valid values are `Container`, `SubContainers`, `ContainerAndSubContainers`, `Leaves`, `ContainerAndLeaves`, `SubContainersAndLeaves`, `ContainerAndSubContainersAndLeaves`, `ChildContainers`, `ContainerAndChildContainers`, `ChildLeaves`, `ContainerAndChildLeaves`, `ChildContainersAndChildLeaves`, `ContainerAndChildContainersAndChildLeaves`.
        $ApplyTo,

        [bool]
        # When granting permissions on files, directories, or registry items, add the permissions as a new access rule instead of replacing any existing access rules. This parameter is ignored when setting permissions on certificates.
        #
        # This parameter was added in Carbon 2.7.
        $Append,
        
        [ValidateSet('Present','Absent')]
        [string]
        # If set to `Present`, permissions are set. If `Absent`, all permissions to `$Path` removed.
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'


    if( $PSBoundParameters.ContainsKey('Ensure') )
    {
        $PSBoundParameters.Remove('Ensure')
    }
    
    if( $Ensure -eq 'Absent' )
    {
        Write-Verbose ('Revoking permission for "{0}" to "{1}"' -f $Identity,$Path)
        Revoke-CPermission -Path $Path -Identity $Identity
    }
    else
    {
        if( -not $Permission )
        {
            Write-Error ('Permission parameter is mandatory when granting permissions. If you want to revoke a user"s permission(s), set the `Ensure` property to `Absent`.')
            return
        }

        Write-Verbose ('Granting permission for "{0}" to "{1}": {2}' -f $Identity,$Path,($Permission -join ','))
        Grant-CPermission @PSBoundParameters
    }
}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions.
        $Identity,
        
        [ValidateSet("CreateFiles","AppendData","CreateSubKey","EnumerateSubKeys","CreateLink","Delete","ChangePermissions","ExecuteFile","DeleteSubdirectoriesAndFiles","FullControl","GenericRead","GenericAll","GenericExecute","QueryValues","ReadAttributes","ReadData","ReadExtendedAttributes","GenericWrite","Notify","ReadPermissions","Read","ReadAndExecute","Modify","SetValue","ReadKey","TakeOwnership","WriteAttributes","Write","Synchronize","WriteData","WriteExtendedAttributes","WriteKey")]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,
        
        [ValidateSet('Container','SubContainers','ContainerAndSubContainers','Leaves','ContainerAndLeaves','SubContainersAndLeaves','ContainerAndSubContainersAndLeaves','ChildContainers','ContainerAndChildContainers','ChildLeaves','ContainerAndChildLeaves','ChildContainersAndChildLeaves','ContainerAndChildContainersAndChildLeaves')]
        [string]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo,

        [bool]
        $Append,
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resources = Get-TargetResource -Identity $Identity -Path $Path
    $desiredRights = ($Permission | Sort-Object) -join ','
    
    if( $Ensure -eq 'Absent' )
    {
        if( -not ($resources | Where-Object { $_.Ensure -eq 'Present' }) )
        {
            Write-Verbose ('[{0}]  [{1}]  No Permissions' -f $Path,$Identity)
            return $true
        }
        
        foreach( $resource in $resources )
        {
            $currentRights = ($resource.Permission | Sort-Object) -join ','
            Write-Verbose ('[{0}]  [{1}]  {2}' -f $Path,$Identity,$currentRights)
        }
        return $false
    }

    if( -not $Permission )
    {
        Write-Error ('Permission parameter is mandatory when granting permissions. If you want to revoke a user"s permission(s), set the `Ensure` property to `Absent`.')
        return
    }

    $upToDate = $false
    $idx = -1
    foreach( $resource in $resources )
    {
        ++$idx
        $currentRights = ($resource.Permission | Sort-Object) -join ','
        if( $desiredRights -ne $currentRights )
        {
            Write-Verbose ('[{0}]  [{1}]  Rule[{2}]  Permission  "{3}" != "{4}"' -f $Path,$Identity,$idx,$currentRights,$desiredRights)
            continue
        }
        else
        {
            Write-Verbose ('[{0}]  [{1}]  Rule[{2}]  Permission  "{3}" == "{4}"' -f $Path,$Identity,$idx,$currentRights,$desiredRights)
        }

        if( $ApplyTo )
        {
            if( $ApplyTo -ne $resource.ApplyTo )
            {
                Write-Verbose ('[{0}]  [{1}]  Rule[{2}]  ApplyTo  "{3}" != "{4}"' -f $Path,$Identity,$idx,$ApplyTo,$resource.ApplyTo)
                continue
            }
            else
            {
                Write-Verbose ('[{0}]  [{1}]  Rule[{2}]  ApplyTo  "{3}" == "{4}"' -f $Path,$Identity,$idx,$ApplyTo,$resource.ApplyTo)
            }
        }

        # We found one access rule that matches. It's up-to-date.
        $upToDate = $true
        break
    }

    return $upToDate
}
