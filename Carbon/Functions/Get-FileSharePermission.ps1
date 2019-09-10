
function Get-CFileSharePermission
{
    <#
    .SYNOPSIS
    Gets the sharing permissions on a file/SMB share.

    .DESCRIPTION
    The `Get-CFileSharePermission` function uses WMI to get the sharing permission on a file/SMB share. It returns the permissions as a `Carbon.Security.ShareAccessRule` object, which has the following properties:

     * ShareRights: the rights the user/group has on the share.
     * IdentityReference: an `Security.Principal.NTAccount` for the user/group who has permission.
     * AccessControlType: the type of access control being granted: Allow or Deny.

    The `ShareRights` are values from the `Carbon.Security.ShareRights` enumeration. There are four values:

     * Read
     * Change
     * FullControl
     * Synchronize

    If the share doesn't exist, nothing is returned and an error is written.

    Use the `Identity` parameter to get a specific user/group's permissions. Wildcards are supported.

    `Get-CFileSharePermission` was added in Carbon 2.0.

    .LINK
    Get-CFileShare

    .LINK
    Install-CFileShare

    .LINK
    Test-CFileShare

    .LINK
    Uninstall-CFileShare

    .EXAMPLE
    Get-CFileSharePermission -Name 'Build'

    Demonstrates how to get all the permissions on the `Build` share.
    #>
    [CmdletBinding()]
    [OutputType([Carbon.Security.ShareAccessRule])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The share's name.
        $Name,

        [string]
        # Get permissions for a specific identity. Wildcards supported.
        $Identity
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $share = Get-CFileShare -Name $Name
    if( -not $share )
    {
        return
    }

    if( $Identity )
    {
        if( -not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters( $Identity ) )
        {
            $Identity = Resolve-CIdentityName -Name $Identity -ErrorAction $ErrorActionPreference
            if( -not $Identity )
            {
                return
            }
        }
    }
        
    $acl = $null  
    $lsss = Get-WmiObject -Class 'Win32_LogicalShareSecuritySetting' -Filter "name='$Name'"
    if( -not $lsss )
    {
        return
    }

    $result = $lsss.GetSecurityDescriptor()
    if( -not $result )
    {
        return
    }

    if( $result.ReturnValue )
    {
        $win32lsssErrors = @{
                                [uint32]2 = 'Access Denied';
                                [uint32]8 = 'Unknown Failure';
                                [uint32]9 = 'Privilege Missing';
                                [uint32]21 = 'Invalid Parameter';
                            }
        Write-Error ('Failed to get ''{0}'' share''s security descriptor. WMI returned error code {1} which means: {2}' -f $Name,$result.ReturnValue,$win32lsssErrors[$result.ReturnValue])
        return
    }

    $sd = $result.Descriptor
    if( -not $sd -or -not $sd.DACL )
    {
        return
    }

    foreach($ace in $SD.DACL)
    {   
        if( -not $ace -or -not $ace.Trustee )
        {
            continue
        }

        [Carbon.Identity]$rId = [Carbon.Identity]::FindBySid( $ace.Trustee.SIDString )
        if( $Identity -and  (-not $rId -or $rId.FullName -notlike $Identity) )
        {
            continue
        }

        if( $rId )
        {
            $aceId = New-Object 'Security.Principal.NTAccount' $rId.FullName
        }
        else
        {
            $aceId = New-Object 'Security.Principal.SecurityIdentifier' $ace.Trustee.SIDString
        }

        New-Object 'Carbon.Security.ShareAccessRule' $aceId, $ace.AccessMask, $ace.AceType
    } 
}

