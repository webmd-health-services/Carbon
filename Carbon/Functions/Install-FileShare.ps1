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

function Install-FileShare
{
    <#
    .SYNOPSIS
    Installs a file/SMB share.

    .DESCRIPTION
    The `Install-FileShare` function installs a new file/SMB share. If the share doesn't exist, it is created. In Carbon 2.0, if a share does exist, its properties and permissions are updated in place, unless the share's path needs to change. Changing a share's path requires deleting and re-creating. Before Carbon 2.0, shares were always deleted and re-created.

    Use the `FullAccess`, `ChangeAccess`, and `ReadAccess` parameters to grant full, change, and read sharing permissions on the share. Each parameter takes a list of user/group names. If you don't supply any permissions, `Everyone` will get `Read` access. Permissions on existing shares are cleared before permissions are granted. Permissions don't apply to the file system, only to the share. Use `Grant-Permission` to grant file system permissions. 

    Before Carbon 2.0, this function was called `Install-SmbShare`.

    .LINK
    Get-FileShare

    .LINK
    Get-FileSharePermission

    .LINK
    Grant-Permission

    .LINK
    Test-FileShare

    .LINK
    Uninstall-FileShare

    .EXAMPLE
    Install-Share -Name TopSecretDocuments -Path C:\TopSecret -Description 'Share for our top secret documents.' -ReadAccess "Everyone" -FullAccess "Analysts"

    Shares the C:\TopSecret directory as `TopSecretDocuments` and grants `Everyone` read access and `Analysts` full control.  
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The share's name.
        $Name,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the share.
        $Path,
            
        [string]
        # A description of the share
        $Description = '',
        
        [string[]]
        # The identities who have full access to the share.
        $FullAccess = @(),
        
        [string[]]
        # The identities who have change access to the share.
        $ChangeAccess = @(),
        
        [string[]]
        # The identities who have read access to the share
        $ReadAccess = @(),

        [Switch]
        # Deletes the share and re-creates it, if it exists. Preserves default beheavior in Carbon before 2.0.
        #
        # The `Force` switch is new in Carbon 2.0.
        $Force
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    function New-ShareAce
    {
        param(
            [Parameter(Mandatory=$true)]
            [AllowEmptyCollection()]
            [string[]]
            # The identity 
            $Identity,

            [Carbon.Security.ShareRights]
            # The rights to grant to Identity.
            $ShareRight
        )

        Set-StrictMode -Version 'Latest'

        foreach( $identityName in $Identity )
        {
            $trustee = ([wmiclass]'Win32_Trustee').CreateInstance()
            [Security.Principal.SecurityIdentifier]$sid = Resolve-Identity -Name $identityName | Select-Object -ExpandProperty 'Sid'
            if( -not $sid )
            {
                continue
            }

            $sidBytes = New-Object 'byte[]' $sid.BinaryLength
            $sid.GetBinaryForm( $sidBytes, 0)

            $trustee.Sid = $sidBytes

            $ace = ([wmiclass]'Win32_Ace').CreateInstance()
            $ace.AccessMask = $ShareRight
            $ace.AceFlags = 0
            $ace.AceType = 0
            $ace.Trustee = $trustee

            $ace
        }
    }

    $errors = @{
                [uint32]2 = 'Access Denied';
                [uint32]8 = 'Unknown Failure';
                [uint32]9 = 'Invalid Name';
                [uint32]10 = 'Invalid Level';
                [uint32]21 = 'Invalid Parameter';
                [uint32]22 = 'Duplicate Share';
                [uint32]23 = 'Restricted Path';
                [uint32]24 = 'Unknown Device or Directory';
                [uint32]25 = 'Net Name Not Found';
            }

    $Path = Resolve-FullPath -Path $Path
    $Path = $Path.Trim('\\')
    # When sharing drives, path must end with \. Otherwise, it shouldn't.
    if( $Path -eq (Split-Path -Qualifier -Path $Path ) )
    {
        $Path = Join-Path -Path $Path -ChildPath '\'
    }

    if( (Test-FileShare -Name $Name) )
    {
        $share = Get-FileShare -Name $Name
        [bool]$delete = $false
        
        if( $Force )
        {
            $delete = $true
        }

        if( $share.Path -ne $Path )
        {
            Write-Verbose -Message ('[SHARE] [{0}] Path         {1} -> {2}.' -f $Name,$share.Path,$Path)
            $delete = $true
        }

        if( $delete )
        {
            Uninstall-FileShare -Name $Name
        }
    }

    $shareAces = Invoke-Command -ScriptBlock {
                                                New-ShareAce -Identity $FullAccess -ShareRight FullControl
                                                New-ShareAce -Identity $ChangeAccess -ShareRight Change
                                                New-ShareAce -Identity $ReadAccess -ShareRight Read
                                           }
    if( -not $shareAces )
    {
        $shareAces = New-ShareAce -Identity 'Everyone' -ShareRight Read
    }

    # if we don't pass a $null security descriptor, default Everyone permissions aren't setup correctly, and extra admin rights are slapped on.
    $shareSecurityDescriptor = ([wmiclass] "Win32_SecurityDescriptor").CreateInstance() 
    $shareSecurityDescriptor.DACL = $shareAces
    $shareSecurityDescriptor.ControlFlags = "0x4"

    if( -not (Test-FileShare -Name $Name) )
    {
        if( -not (Test-Path -Path $Path -PathType Container) )
        {
            New-Item -Path $Path -ItemType Directory -Force | Out-String | Write-Verbose
        }
    
        $shareClass = Get-WmiObject -Class 'Win32_Share' -List
        Write-Verbose -Message ('[SHARE] [{0}]              Sharing {1}' -f $Name,$Path)
        $result = $shareClass.Create( $Path, $Name, 0, $null, $Description, $null, $shareSecurityDescriptor )
        if( $result.ReturnValue )
        {
            Write-Error ('Failed to create share ''{0}'' (Path: {1}). WMI returned error code {2} which means: {3}.' -f $Name,$Path,$result.ReturnValue,$errors[$result.ReturnValue])
            return
        }
    }
    else
    {
        $share = Get-FileShare -Name $Name
        $updateShare = $false
        if( $share.Description -ne $Description )
        {
            Write-Verbose -Message ('[SHARE] [{0}] Description  {1} -> {2}' -f $Name,$share.Description,$Description)
            $updateShare = $true
        }

        # Check if the share is missing any of the new ACEs.
        foreach( $ace in $shareAces )
        {
            $identityName = Resolve-IdentityName -SID $ace.Trustee.SID
            $permission = Get-FileSharePermission -Name $Name -Identity $identityName

            if( -not $permission )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}:  -> {2}' -f $Name,$identityName,([Carbon.Security.ShareRights]$ace.AccessMask))
                $updateShare = $true
            }
            elseif( [int]$permission.ShareRights -ne $ace.AccessMask )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}: {2} -> {3}' -f $Name,$identityName,$permission.ShareRights,([Carbon.Security.ShareRights]$ace.AccessMask))
                $updateShare = $true
            }
        }

        # Now, check that there aren't any existing ACEs that need to get deleted.
        $existingAces = Get-FileSharePermission -Name $Name
        foreach( $ace in $existingAces )
        {
            $identityName = $ace.IdentityReference.Value

            $existingAce = $ace
            if( $shareAces )
            {
                $existingAce = $shareAces | Where-Object { 
                                                        $newIdentityName = Resolve-IdentityName -SID $_.Trustee.SID
                                                        return ( $newIdentityName -eq $ace.IdentityReference.Value )
                                                    }
            }

            if( -not $existingAce )
            {
                Write-Verbose -Message ('[SHARE] [{0}] Access       {1}: {2} ->' -f $Name,$identityName,$ace.ShareRights)
                $updateShare = $true
            }
        }

        if( $updateShare )
        {
            $result = $share.SetShareInfo( $share.MaximumAllowed, $Description, $shareSecurityDescriptor )
            if( $result.ReturnValue )
            {
                Write-Error ('Failed to create share ''{0}'' (Path: {1}). WMI returned error code {2} which means: {3}' -f $Name,$Path,$result.ReturnValue,$errors[$result.ReturnValue])
                return
            }
        }
    }
}

Set-Alias -Name 'Install-SmbShare' -Value 'Install-FileShare'
