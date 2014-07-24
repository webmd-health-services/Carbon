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
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity of the principal whose privileges to get.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]]
        # The user's expected/desired privileges.
        $Privilege,
        
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    [string[]]$currentPrivileges = Get-Privilege -Identity $Identity
    $Ensure = 'Present'
    if( -not $currentPrivileges )
    {
        [string[]]$currentPrivileges = @()
    }

    foreach( $item in $Privilege )
    {
        if( $currentPrivileges -notcontains $item )
        {
            $Ensure = 'Absent'
            break
        }
    }

    foreach( $item in $currentPrivileges )
    {
        if( $Privilege -notcontains $item )
        {
            $Ensure = 'Absent'
            break
        }
    }

    $resource = @{
                    Identity = $Identity;
                    Privilege = $currentPrivileges;
                    Ensure = $Ensure;
                }

    
    return $resource
}


function Set-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity of the principal whose privileges to set.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]]
        # The user's expected/desired privileges.
        $Privilege,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $currentPrivileges = Get-Privilege -Identity $Identity
    if( $currentPrivileges )
    {
        Write-Verbose ('Revoking ''{0}'' privileges: {1}' -f $Identity,($currentPrivileges -join ','))
        Revoke-Privilege -Identity $Identity -Privilege $currentPrivileges
    }

    if( $Ensure -eq 'Present' )
    {
        Write-Verbose ('Granting ''{0}'' privileges: {1}' -f $Identity,($Privilege -join ','))
        Grant-Privilege -Identity $Identity -Privilege $Privilege
    }
}


function Test-TargetResource
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The identity of the principal whose privileges to test.
        $Identity,
        
        [Parameter(Mandatory=$true)]
        [AllowEmptyCollection()]
        [string[]]
        # The user's expected/desired privileges.
        $Privilege,
        
        [Parameter(Mandatory=$true)]
        [ValidateSet('Present','Absent')]
        [string]
        # Should the user exist or not exist?
        $Ensure
    )

    Set-StrictMode -Version 'Latest'

    $resource = Get-TargetResource -Identity $Identity -Privilege $Privilege

    $privilegeMissing = $resource.Ensure -eq 'Absent'
    if( $Ensure -eq 'Absent' )
    {
        $absent = $resource.Privilege.Length -eq 0
        if( $absent )
        {
            Write-Verbose ('Identity ''{0}'' has no privileges' -f $Identity)
            return $true
        }
        
        Write-Verbose ('Identity ''{0}'' has privilege(s) {1}' -f $Identity,($resource.Privilege -join ','))
        return $false
    }

    if( $privilegeMissing )
    {
        $msgParts = @()
        $extraPrivileges = $resource.Privilege | Where-Object { $Privilege -notcontains $_ }
        if( $extraPrivileges )
        {
            $msgParts += 'extra privilege(s): {0}' -f ($extraPrivileges -join ',')
        }

        $missingPrivileges = $Privilege | Where-Object { $resource.Privilege -notcontains $_ }
        if( $missingPrivileges )
        {
            $msgParts += 'missing privilege(s): {0}' -f ($missingPrivileges -join ',')
        }
        Write-Verbose ('Identity ''{0}'' {1}' -f $Identity,($msgParts -join '; '))
        return $false
    }

    return $true
}