
function Install-CFileShare
{
    <#
    .SYNOPSIS
    Installs a file/SMB share.

    .DESCRIPTION
    The `Install-CFileShare` function installs a new file/SMB share. If the share doesn't exist, it is created. In Carbon 2.0, if a share does exist, its properties and permissions are updated in place, unless the share's path needs to change. Changing a share's path requires deleting and re-creating. Before Carbon 2.0, shares were always deleted and re-created.

    Use the `FullAccess`, `ChangeAccess`, and `ReadAccess` parameters to grant full, change, and read sharing permissions on the share. Each parameter takes a list of user/group names. If you don't supply any permissions, `Everyone` will get `Read` access. Permissions on existing shares are cleared before permissions are granted. Permissions don't apply to the file system, only to the share. Use `Grant-CPermission` to grant file system permissions.

    Before Carbon 2.0, this function was called `Install-SmbShare`.

    .LINK
    Get-CFileShare

    .LINK
    Get-CFileSharePermission

    .LINK
    Grant-CPermission

    .LINK
    Test-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Install-Share -Name TopSecretDocuments -Path C:\TopSecret -Description 'Share for our top secret documents.' -ReadAccess "Everyone" -FullAccess "Analysts"

    Shares the C:\TopSecret directory as `TopSecretDocuments` and grants `Everyone` read access and `Analysts` full control.
    #>
    [CmdletBinding()]
    param(
        # The share's name.
        [Parameter(Mandatory)]
        [String] $Name,

        # The path to the share.
        [Parameter(Mandatory)]
        [String] $Path,

        # A description of the share
        [String] $Description = '',

        # The identities who have full access to the share.
        [String[]] $FullAccess = @(),

        # The identities who have change access to the share.
        [String[]] $ChangeAccess = @(),

        # The identities who have read access to the share
        [String[]] $ReadAccess = @(),

        # Deletes the share and re-creates it, if it exists. Preserves default beheavior in Carbon before 2.0.
        #
        # The `Force` switch is new in Carbon 2.0.
        [switch] $Force
    )

    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    if (-not (Get-Command -Name 'Get-WmiObject' -ErrorAction Ignore))
    {
        # No. Seriously. The CIM cmdlets have no way of creating Win32_SecurityDescriptor
        $msg = "$($PSCmdlet.MyInvocation.MyCommand.Name) is not supported because the Get-WmiObject cmdlet does not " +
               'exist.'
        Write-Error -Message $msg -ErrorAction $ErrorActionPreference
        return
    }

    function New-ShareAce
    {
        param(
            # The identity
            [Parameter(Mandatory)]
            [AllowEmptyCollection()]
            [String[]] $Identity,

            # The rights to grant to Identity.
            [Carbon.Security.ShareRights] $ShareRight
        )

        Set-StrictMode -Version 'Latest'

        foreach( $identityName in $Identity )
        {
            $trustee = ([wmiclass]'Win32_Trustee').CreateInstance()
            [Security.Principal.SecurityIdentifier]$sid =
                Resolve-CIdentity -Name $identityName -NoWarn | Select-Object -ExpandProperty 'Sid'
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

    $Path = Resolve-CFullPath -Path $Path -NoWarn
    $Path = $Path.Trim('\\')
    # When sharing drives, path must end with \. Otherwise, it shouldn't.
    if( $Path -eq (Split-Path -Qualifier -Path $Path ) )
    {
        $Path = Join-Path -Path $Path -ChildPath '\'
    }

    $changeMsgPrefix = "  "
    $changeMsgs = [Collections.Generic.List[String]]::New()
    $action = 'Creating'

    if( (Test-CFileShare -Name $Name) )
    {
        $share = Get-CFileShare -Name $Name
        [bool]$delete = $false

        if( $Force )
        {
            $delete = $true
        }

        if ($share.Path -ne $Path)
        {
            $action = 'Updating'
            $delete = $true
        }

        if( $delete )
        {
            Uninstall-CFileShare -Name $Name -InformationAction SilentlyContinue
        }
    }

    $createdShare = $false
    if (-not (Test-CFileShare -Name $Name))
    {
        Install-CDirectory -Path $Path

        Write-Information -Message "$($action) SMB file share ""$($Name)""."
        if ($action -eq 'Creating')
        {
            Write-Information "$($changeMsgPrefix)Path         $($Path)"
            if ($Description)
            {
                Write-Information "$($changeMsgPrefix)Description  $($Description)"
            }
        }
        elseif ($action -eq 'Updating' -and $share.Path -ne $Path)
        {
            WRite-Information "$($changeMsgPrefix)Path         $($share.Path) -> $($Path)"
        }

        $createArgs = [ordered]@{
            Path = [String]$Path;
            Name = [String]$Name;
            Type = [UInt32]0;
            MaximumAllowed = $null;
            Description = $Description;
        }
        Invoke-CCimMethod -ClassName 'Win32_Share' -Name 'Create' -Arguments $createArgs
        $createdShare = $true
    }

    $share = Get-CFileShare -Name $Name -AsWmiObject
    $updateShare = $false

    if ($share.Description -ne $Description)
    {
        $changeMsgs.Add("$($changeMsgPrefix)Description  $($share.Description) -> $($Description)")
        $updateShare = $true
    }

    $shareAces = Invoke-Command -ScriptBlock {
            if (-not $FullAccess -and -not $ChangeAccess -and -not $ReadAccess)
            {
                return New-ShareAce -Identity 'Everyone' -ShareRight Read
            }

            New-ShareAce -Identity $FullAccess -ShareRight FullControl
            New-ShareAce -Identity $ChangeAccess -ShareRight Change
            New-ShareAce -Identity $ReadAccess -ShareRight Read
        }

    # Check if the share is missing any of the new ACEs.
    foreach ($ace in $shareAces)
    {
        $identityName = Resolve-CIdentityName -SID $ace.Trustee.SID -NoWarn
        $accessMsgPrefix = "$($changeMsgPrefix)Access       $($identityName)  "
        $permission = Get-CFileSharePermission -Name $Name -Identity $identityName

        $newPerm = [Carbon.Security.ShareRights]$ace.AccessMask
        if (-not $permission)
        {
            $changeMsgs.Add("$($accessMsgPrefix)+ $($newPerm)")
            $updateShare = $true
        }
        elseif ([int]$permission.ShareRights -ne $ace.AccessMask)
        {
            $changeMsgs.Add("$($accessMsgPrefix)  $($permission.ShareRights) -> $($newPerm)")
            $updateShare = $true
        }
    }

    $existingAces = Get-CFileSharePermission -Name $Name
    foreach ($ace in $existingAces)
    {
        $identityName = $ace.IdentityReference.Value

        $existingAce = $ace
        if ($shareAces)
        {
            $existingAce =
                $shareAces |
                Where-Object {
                        $newIdentityName = Resolve-CIdentityName -SID $_.Trustee.SID -NoWarn
                        return ( $newIdentityName -eq $ace.IdentityReference.Value )
                    }
        }

        if (-not $existingAce)
        {
            $changeMsgs.Add("$($changeMsgPrefix)Access       $($identityName)  - $($ace.ShareRights)")
            $updateShare = $true
        }
    }

    if ($updateShare)
    {
        $currentSD = Get-CFileShareSecurityDescriptor -Name $Name
        $newSD = ([wmiclass]'Win32_SecurityDescriptor').CreateInstance()
        $newSD.DACL = $shareAces
        $newSD.ControlFlags = "0x4"
        $newSD.Group = $currentSD.Group
        $newSD.Owner = $currentSD.Owner
        $newSD.SACL = $currentSD.SACL

        if (-not $createdShare)
        {
            Write-Information -Message "Updating SMB file share ""$($Name)""."
        }
        foreach ($msg in $changeMsgs)
        {
            Write-Information $msg
        }

        $result = $share.SetShareInfo($share.MaximumAllowed, $Description, $newSD)
        Write-CCimError -Message "Failed to update ""$($Name)"" SMB file share" -Result $result
    }
}

Set-Alias -Name 'Install-SmbShare' -Value 'Install-CFileShare'
