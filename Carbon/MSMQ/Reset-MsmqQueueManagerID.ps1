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

function Reset-MsmqQueueManagerID
{
    <#
    .SYNOPSIS
    Resets the MSMQ Queue Manager ID.
    
    .DESCRIPTION
    Removes any existing MSMQ Queue Manager ID in the registry and restarts MSMQ so that it will generate a fresh QM ID.

    Each instance of MSMQ should have its own unique Queue Manager ID. If multiple machines have the same Queue Manager ID, destination queues think messages are actually coming from the same computer, and messages are lost/dropped.  If you clone new servers from a template or from old servers, you'll get duplicate Queue Manager IDs.  This function causes MSMQ to reset its Queue Manager ID.
    
    .EXAMPLE
    Reset-MsmqQueueManagerId
    
    .LINK
    http://blogs.msdn.com/b/johnbreakwell/archive/2007/02/06/msmq-prefers-to-be-unique.aspx
    #>
    [CmdletBinding()]
    param(
    )

    Write-Verbose "Resetting MSMQ Queue Manager ID."
    Write-Verbose "Stopping MSMQ."
    Stop-Service MSMQ -Force
    
    $QMIdPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters\MachineCache"
    $QMIdName = "QMId"
   	$QMId = Get-RegistryKeyValue -Path $QMIdPath -Name $QMIdName
   	Write-Verbose "Existing QMId: $QMId"
   	Remove-RegistryKeyValue -Path $QMIdPath -Name $QMIdName
    
    $MSMQSysPrepPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
    $MSMQSysPrepName = "SysPrep"
   	Remove-RegistryKeyValue -Path $MSMQSysPrepPath -Name $MSMQSysPrepName
	Set-RegistryKeyValue -Path $MSMQSysPrepPath -Name $MSMQSysPrepName -DWord 1
    
    Write-Verbose "Starting MSMQ"
    Start-Service MSMQ
    
	$QMId = Get-RegistryKeyValue -Path $QMIdPath -Name $QMIdName
    Write-Verbose "New QMId: $QMId"
}
