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

function Get-FileSharePermission
{
    <#
    .SYNOPSIS
    Gets the sharing permissions on a file/SMB share.

    .DESCRIPTION
    The `Get-FileSharePermission` function uses WMI to get the sharing permission on a file/SMB share. It returns the permissions as a `Carbon.Security.ShareAccessRule` object, which has the following properties:

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

    `Get-FileSharePermission` was added in Carbon 2.0.

    .LINK
    Get-FileShare

    .LINK
    Install-FileShare

    .LINK
    Test-FileShare

    .LINK
    Uninstall-FileShare

    .EXAMPLE
    Get-FileSharePermission -Name 'Build'

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

    $share = Get-FileShare -Name $Name
    if( -not $share )
    {
        return
    }

    if( $Identity )
    {
        if( -not [System.Management.Automation.WildcardPattern]::ContainsWildcardCharacters( $Identity ) )
        {
            $Identity = Resolve-IdentityName -Name $Identity -ErrorAction $ErrorActionPreference
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

