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

$carbonWin32MemberDefinition = @'
[DllImport("kernel32.dll", SetLastError=true, CharSet=CharSet.Auto)]
public static extern uint GetLongPathName(
    string shortPath, 
    StringBuilder sb, 
    int buffer);

[DllImport("kernel32.dll", CharSet = CharSet.Auto, SetLastError=true)]
public static extern uint GetShortPathName(
   string lpszLongPath,
   StringBuilder lpszShortPath,
   uint cchBuffer);

[DllImport("shlwapi.dll", CharSet=CharSet.Auto)]
public static extern bool PathRelativePathTo(
     [Out] StringBuilder pszPath,
     [In] string pszFrom,
     [In] FileAttributes dwAttrFrom,
     [In] string pszTo,
     [In] FileAttributes dwAttrTo
);
'@
Add-Type -MemberDefinition $carbonWin32MemberDefinition -Name 'Win32' -Namespace 'Carbon' -UsingNamespace System.Text,System.IO


function Get-FullPath($relativePath)
{
    if( -not ( [System.IO.Path]::IsPathRooted($relativePath) ) )
    {
        Write-Warning "Path to resolve is not rooted.  Please pass a rooted path to Get-FullPath.  Path.GetFullPath uses Environment.CurrentDirectory as the path root, which PowerShell doesn't update."
    }
    return [System.IO.Path]::GetFullPath($relativePath)
}

function Get-PathCanonicalCase
{
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # Gets the real case of a path
        $Path
    )
    
    if( -not (Test-Path $Path) )
    {
        Write-Error "Path '$Path' doesn't exist."
        return
    }
    
    $shortBuffer = New-Object Text.StringBuilder ($Path.Length * 2)
    [void] [Carbon.Win32]::GetShortPathName( $Path, $shortBuffer, $shortBuffer.Capacity )
    
    $longBuffer = New-Object Text.StringBuilder ($Path.Length * 2)
    [void] [Carbon.Win32]::GetLongPathName( $shortBuffer.ToString(), $longBuffer, $longBuffer.Capacity )
    
    return $longBuffer.ToString()
}

function Get-PathRelativeTo
{
    param(
        [Parameter(Mandatory=$true,Position=0)]
        $From,
        
        [Parameter(Position=1)]
        [ValidateSet('Directory', 'File')]
        $FromType = 'Directory',
        
        [Parameter(ValueFromPipeline=$true)]
        $To
    )
    
    process
    {
        $relativePath = New-Object System.Text.StringBuilder 260
        $fromAttr = [System.IO.FileAttributes]::Directory
        if( $FromType -eq 'File' )
        {
            $fromAttr = [System.IO.FileAttributes]::Normal
        }
        
        $toPath = $To
        if( $To.FullName )
        {
            $toPath = $To.FullName
        }
        
        $toAttr = [System.IO.FileAttributes]::Normal
        $converted = [Carbon.Win32]::PathRelativePathTo( $relativePath, $From, $fromAttr, $toPath, $toAttr )
        $result = if( $converted ) { $relativePath.ToString() } else { $null }
        return $result
    }
}

function Grant-Permissions
{
    <#
    .SYNOPSIS
    Grants permission on a file/directory or registry key.
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.filesystemrights.aspx
    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.accesscontrol.registryrights.aspx
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The user or group getting the permissions
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [string[]]
        # The permission: e.g. FullControl, Read, etc.  For file system items, use values from
        # System.Security.AccessControl.FileSystemRights.  For registry items, use values from
        # System.Security.AccessControl.RegistryRights.
        $Permissions,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path on which the permissions should be granted.  Can be a file system or registry path.
        $Path
    )
    
    $Path = Resolve-Path $Path
    
    $pathQualifier = Split-Path -Qualifier $Path
    if( -not $pathQualifier )
    {
        throw "Unable to get qualifier on path $Path."
    }
    $pathDrive = Get-PSDrive $pathQualifier.Trim(':')
    $pathProvider = $pathDrive.Provider
    $providerName = $pathProvider.Name
    if( $providerName -ne 'Registry' -and $providerName -ne 'FileSystem' )
    {
        throw "Unsupported path: '$Path' belongs to the '$providerName' provider."
    }

    $rights = 0
    foreach( $permission in $Permissions )
    {
        $right = ($permission -as "Security.AccessControl.$($providerName)Rights")
        if( -not $right )
        {
            throw "Invalid $($providerName)Rights: $permission.  Must be one of $([Enum]::GetNames("Security.AccessControl.$($providerName)Rights"))."
        }
        $rights = $rights -bor $right
    }
    
    Write-Host "Granting $Identity $Permissions on $Path."
    # We don't use Get-Acl because it returns the whole security descriptor, which includes owner information.
    # When passed to Set-Acl, this causes intermittent errors.  So, we just grab the ACL portion of the security descriptor.
    # See http://www.bilalaslam.com/2010/12/14/powershell-workaround-for-the-security-identifier-is-not-allowed-to-be-the-owner-of-this-object-with-set-acl/
    $currentAcl = (Get-Item $Path).GetAccessControl("Access")
    
    $inheritanceFlags = [Security.AccessControl.InheritanceFlags]::None
    if( Test-Path $Path -PathType Container )
    {
        $inheritanceFlags = ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                             [Security.AccessControl.InheritanceFlags]::ObjectInherit)
    }
    $propagationFlags = [Security.AccessControl.PropagationFlags]::None
    $accessRule = New-Object "Security.AccessControl.$($providerName)AccessRule" $identity,$rights,$inheritanceFlags,$propagationFlags,"Allow"    
    $currentAcl.SetAccessRule( $accessRule )
    Set-Acl $Path $currentAcl
}

function New-Junction
{
    param(
        [Parameter(Mandatory=$true)]
        [Alias("Junction")]
        [string]
        # The new junction to create
        $Link,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The target of the junction, i.e. where the junction will point to
        $Target
    )
    
    if( Test-Path $Link -PathType Container )
    {
        Write-Error "'$Link' already exists."
    }
    else
    {
        cmd.exe /c mklink /J $Link $Target | Write-Host
        if( $LastExitCode -eq 0 ) 
        { 
            Get-Item $Link 
        } 
    }
}

function New-TempDir
{
    $tmpPath = [System.IO.Path]::GetTempPath()
    $newTmpDirName = [System.IO.Path]::GetRandomFileName()
    New-Item (Join-Path $tmpPath $newTmpDirName) -Type directory
}

function Remove-Junction
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [string]
        # The path to the junction to remove
        $Path
    )
    
    if( Test-PathIsJunction $Path  )
    {
        if( $pscmdlet.ShouldProcess($Path, "remove junction") )
        {
            Write-Host "Removing junction $Path."
            cmd.exe /c rmdir $Path
        }
    }
    else
    {
        Write-Error "'$Path' doesn't exist or is not a junction."
    }
}

function Test-PathIsJunction
{
    param(
        [string]
        # The path to check
        $Path
    )
    
    if( Test-Path $Path -PathType Container )
    {
        $item = Get-Item $Path
        return $item.Attributes -like '*ReparsePoint*'
    }
    return $false
}

