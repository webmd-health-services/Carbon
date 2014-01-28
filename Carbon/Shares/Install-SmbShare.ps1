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

function Install-SmbShare
{
    <#
    .SYNOPSIS
    Creates a share, replacing any existing share with the same name.

    .DESCRIPTION
    Creates a new Windows SMB share, or replaces an existing share with the same name.  Optionally grants permissions on that share.  Unfortunately, there isn't a way in Carbon to set permissions on a share after it is created.  Send us the code!

    Permissions don't apply to the file system.  They only apply to the share.  Use `Grant-Permission` to grant file system permissions.

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
        $ReadAccess = @()
    )
    
    function ConvertTo-NetShareGrantArg
    {
        param(
            [string[]]
            $Name,
            
            [string]
            [ValidateSet('FULL','CHANGE','READ')]
            $Access
        )
        $Name | ForEach-Object {
            $perm = ''
            if( $Access -ne 'NONE' )
            {
                $perm = ',{0}' -f $Access
            }
            '/GRANT:{0}{1}' -f $_,$perm
        }
    }

    $share = Get-WmiObject Win32_Share -Filter "Name='$Name'"
    if( $share -ne $null )
    {
        Write-Verbose "Share '$Name' exists and will be deleted."
        [void] $share.Delete()
    }

    $fullAccessArg = ConvertTo-NetShareGrantArg -Name $FullAccess -Access 'FULL'
    $changeAccessArg = ConvertTo-NetShareGrantArg -Name $ChangeAccess -Access 'CHANGE'
    $readAccessArg = ConvertTo-NetShareGrantArg -Name $ReadAccess -Access 'READ'

    # Create the share's path if it does not exist.
    if( -not (Test-Path -Path $Path -PathType Container) )
    {
        $null = New-Item -Path $Path -ItemType Directory -Force
    }
    
    & (Resolve-NetPath) share $Name=$($Path.Trim('\')) /REMARK:$Description $fullAccessArg $changeAccessArg $readAccessArg /CACHE:NONE /UNLIMITED
}
