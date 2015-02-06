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
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = @{
                    Path = $Path;
                    Identity = $Identity;
                    Permission = @();
                    ApplyTo = $null;
                    Ensure = 'Absent';
                }

    $perm = Get-Permission -Path $Path -Identity $Identity
    if( $perm )
    {
        [string[]]$resource.Permission = $perm | 
                                            Get-Member -Name '*Rights' -MemberType Property | 
                                            ForEach-Object { ($perm.($_.Name)).ToString() -split ',' } |
                                            ForEach-Object { $_.Trim() } | 
                                            Where-Object { $_ -ne 'Synchronize' }

        $resource.ApplyTo = ConvertTo-ContainerInheritanceFlags -InheritanceFlags $perm.InheritanceFlags -PropagationFlags $perm.PropagationFlags
        $resource.Ensure = 'Present'
    }

    return $resource
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

    ### Revoking Permission
        
    Permissions are revoked when the `Ensure` property is set to `Absent`. *All* a user or group's permissions are revoked. You can't revoke part of a principal's access. If you want to revoke part of a principal's access, set the `Ensure` property to `Present` and the `Permissions` property to the list of properties you want the principal to have.

    `Carbon_Permission` is new in Carbon 2.0.

    .LINK
    Get-Permission

    .LINK
    Grant-Permission

    .LINK
    Revoke-Permission

    .LINK
    Test-Permission

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
        Write-Verbose ('Revoking permission for ''{0}'' to ''{1}''' -f $Identity,$Path)
        Revoke-Permission -Path $Path -Identity $Identity
    }
    else
    {
        if( -not $Permission )
        {
            Write-Error ('Permission parameter is mandatory when granting permissions.')
            return
        }

        Write-Verbose ('Granting permission for ''{0}'' to ''{1}'': {2}' -f $Identity,$Path,($Permission -join ','))
        Grant-Permission @PSBoundParameters
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
        
        [Parameter(Mandatory=$true)]
        [ValidateSet("CreateFiles","AppendData","CreateSubKey","EnumerateSubKeys","CreateLink","Delete","ChangePermissions","ExecuteFile","DeleteSubdirectoriesAndFiles","FullControl","GenericRead","GenericAll","GenericExecute","QueryValues","ReadAttributes","ReadData","ReadExtendedAttributes","GenericWrite","Notify","ReadPermissions","Read","ReadAndExecute","Modify","SetValue","ReadKey","TakeOwnership","WriteAttributes","Write","Synchronize","WriteData","WriteExtendedAttributes","WriteKey")]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from [System.Security.AccessControl.FileSystemRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx).  For registry items, use values from [System.Security.AccessControl.RegistryRights](http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx).
        $Permission,
        
        [ValidateSet('Container','SubContainers','ContainerAndSubContainers','Leaves','ContainerAndLeaves','SubContainersAndLeaves','ContainerAndSubContainersAndLeaves','ChildContainers','ContainerAndChildContainers','ChildLeaves','ContainerAndChildLeaves','ChildContainersAndChildLeaves','ContainerAndChildContainersAndChildLeaves')]
        [string]
        # How to apply container permissions.  This controls the inheritance and propagation flags.  Default is full inheritance, e.g. `ContainersAndSubContainersAndLeaves`. This parameter is ignored if `Path` is to a leaf item.
        $ApplyTo,
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure = 'Present'
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Identity $Identity -Path $Path
    $desiredRights = ($Permission | Sort-Object) -join ','
    $currentRights = ($resource.Permission | Sort-Object) -join ','
    
    if( $Ensure -eq 'Absent' )
    {
        if( $resource.Ensure -eq 'Absent' )
        {
            Write-Verbose ('Identity ''{0}'' has no permission to ''{1}''' -f $Identity,$Path)
            return $true
        }
        
        Write-Verbose ('Identity ''{0}'' has permission to ''{1}'': {2}' -f $Identity,$Path,$currentRights)
        return $false
    }

    if( -not $currentRights )
    {
        Write-Verbose ('Identity ''{0} has no permission to ''{1}''' -f $Identity,$Path,$currentRights)
        return $false
    }

    if( $desiredRights -ne $currentRights )
    {
        Write-Verbose ('Identity ''{0} has stale permission to ''{1}'': {2}' -f $Identity,$Path,$currentRights)
        return $false
    }

    if( $ApplyTo -and $ApplyTo -ne $resource.ApplyTo )
    {
        Write-Verbose ('Identity ''{0}'' has stale inheritance/propagation flags to ''{1}'': {2}' -f $Identity,$Path,$resource.ApplyTo)
        return $false
    }

    return $true
}