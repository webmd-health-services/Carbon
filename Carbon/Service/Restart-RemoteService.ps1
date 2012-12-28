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

function Restart-RemoteService
{
    <#
    .SYNOPSIS
    Restarts a service on a remote machine.

    .DESCRIPTION
    One of the annoying features of PowerShell is that the `Stop-Service`, `Start-Service` and `Restart-Service` cmdlets don't have `ComputerName` parameters to start/stop/restart a service on a remote computer.  You have to use `Get-Service` to get the remote service:

        $service = Get-Service -Name DeathStar -ComputerName Yavin
        $service.Stop()
        $service.Start()

        # or (and no, you can't pipe the service directly to `Restart-Service`)
        Get-Service -Name DeathStar -ComputerName Yavin | 
            ForEach-Object { Restart-Service -InputObject $_ }
    
    This function does all this unnecessary work for you.

    You'll get an error if you attempt to restart a non-existent service.

    .EXAMPLE
    Restart-RemoteService -Name DeathStar -ComputerName Yavin

    Restarts the `DeathStar` service on Yavin.  If the DeathStar service doesn't exist, you'll get an error.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The service name to restart.
        $Name,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the computer where the service lives.
        $ComputerName
    )
    
    $service = Get-Service -Name $name -ComputerName $computerName
    if($service)
    {
        if($pscmdlet.ShouldProcess( "$name on $computerName", "restart"))
        {
            $service.Stop()
            $service.Start()
        }
    }
    else
    {
        Write-Error "Unable to restart remote service because I could not get a reference to service $name on machine: $computerName"
    }  
}
 