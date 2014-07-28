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

function Grant-ServiceControlPermission
{
    <#
    .SYNOPSIS
    Grants a user/group permission to start/stop (i.e. use PowerShell's `*-Service` cmdlets) a service.

    .DESCRIPTION
    By default, only Administrators are allowed to control a service. You may notice that when running the `Stop-Service`, `Start-Service`, or `Restart-Service` cmdlets as a non-Administrator, you get permissions errors. That's because you need to correct permissions.  This function grants just the permissions needed to use PowerShell's `Stop-Service`, `Start-Service`, and `Restart-Service` cmdlets to control a service.

    .LINK
    Get-ServicePermission
    
    .LINK
    Grant-ServicePermission
    
    .LINK
    Revoke-ServicePermission
    
    .EXAMPLE
    Grant-ServiceControlPermission -ServiceName CCService -Identity INITRODE\Builders

    Grants the INITRODE\Builders group permission to control the CruiseControl.NET service.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the service.
        $ServiceName,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user/group name being given access.
        $Identity
    )
   
    if( $pscmdlet.ShouldProcess( $ServiceName, "grant control service permissions to '$Identity'" ) )
    {
        Grant-ServicePermission -Name $ServiceName -Identity $Identity -QueryStatus -EnumerateDependents -Start -Stop
    }
}
