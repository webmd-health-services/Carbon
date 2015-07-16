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

    .LINK
    Get-FileShare

    .LINK
    Install-SmbShare

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
        $Name
    )

    Set-StrictMode -Version 'Latest'

    $share = Get-FileShare -Name $Name
    if( -not $share )
    {
        return
    }
  
    $acl = $null  
    $objShareSec = Get-WmiObject -Class 'Win32_LogicalShareSecuritySetting' -Filter "name='$Name'"

    $SD = $objShareSec.GetSecurityDescriptor().Descriptor    
    foreach($ace in $SD.DACL)
    {   
        
        $identity = [Carbon.Identity]::FindBySid( $ace.Trustee.SIDString )
        if( $identity )
        {
            $identity = New-Object 'Security.Principal.NTAccount' $identity.FullName
        }
        else
        {
            $identity = New-Object 'Security.Principal.SecurityIdentifier' $ace.Trustee.SIDString
        }

        New-Object 'Carbon.Security.ShareAccessRule' $identity, $ace.AccessMask, $ace.AceType
    } 
}
