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

function Resolve-IdentityName
{
    <#
    .SYNOPSIS
    Determines the full, NT identity name for a user or group.
    
    .DESCRIPTION
    `Resolve-IdentityName` resolves a user/group name into its full, canonical name, used by the operating system. For example, the local Administrators group is actually called BUILTIN\Administrators. With a canonical username, you can unambiguously compare principals on objects that contain user/group information.

    If unable to resolve a name into an identity, `Resolve-IdentityName` returns nothing.

    If you want to get full identity information (domain, type, sid, etc.), use `Resolve-Identity`.

    In Carbon 2.0, you can also resolve a SID into its identity name. The `SID` parameter accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes. If the SID no longer maps to an active account, you'll get the original SID in SDDL form (as a string) returned to you.

    .LINK
    ConvertTo-SecurityIdentifier

    .LINK
    Resolve-Identity

    .LINK
    Test-Identity

    .LINK
    http://msdn.microsoft.com/en-us/library/system.security.principal.securityidentifier.aspx

    .LINK
    http://msdn.microsoft.com/en-us/library/windows/desktop/aa379601.aspx
    
    .OUTPUTS
    string
    
    .EXAMPLE
    Resolve-IdentityName -Name 'Administrators'
    
    Returns `BUILTIN\Administrators`, the canonical name for the local Administrators group.
    #>
    [CmdletBinding(DefaultParameterSetName='ByName')]
    [OutputType([string])]
    param(
        [Parameter(Mandatory=$true,ParameterSetName='ByName',Position=0)]
        [string]
        # The name of the identity to return.
        $Name,

        [Parameter(Mandatory=$true,ParameterSetName='BySid')]
        # Get an identity's name from its SID. Accepts a SID in SDDL form as a `string`, a `System.Security.Principal.SecurityIdentifier` object, or a SID in binary form as an array of bytes.
        #
        # This parameter is new in Carbon 2.0.
        $SID
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    if( $PSCmdlet.ParameterSetName -eq 'ByName' )
    {
        return Resolve-Identity -Name $Name -ErrorAction Ignore | Select-Object -ExpandProperty 'FullName'
    }
    elseif( $PSCmdlet.ParameterSetName -eq 'BySid' )
    {
        $SID = ConvertTo-SecurityIdentifier -SID $SID
        if( -not $SID )
        {
            return
        }

        $id = [Carbon.Identity]::FindBySid( $SID )
        if( $id )
        {
            return $id.FullName
        }
        else
        {
            return $SID.ToString()
        }
    }
    
}

