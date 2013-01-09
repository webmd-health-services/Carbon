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

function Uninstall-MsmqMessageQueue
{
    <#
    .SYNOPSIS
    Removes an MSMQ queue.

    .DESCRIPTION
    Removes/deletes an existing MSMQ queue by name.  If a queue with that name doesn't exist, nothing happens.

    .EXAMPLE
    Uninstall-MsmqMessageQueue -Name MovieQueue

    Removes the public `MovieQueue` queue.

    .EXAMPLE
    Uninstall-MsmqMessageQueue -Name MovieCriticsQueue -Private

    Removes the private `MovieCriticsQueue` queue.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue to remove.
        $Name,
        
        [Switch]
        # Is this a private queue?
        $Private
    )
    
    $commonArgs = @{ 'Name' = $Name ; 'Private' = $Private }
    
    if( -not (Test-MsmqMessageQueue @commonArgs) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( "MSMQ Message Queue $Name", "remove" ) )
    {
        try
        {
            [Messaging.MessageQueue]::Delete( (Get-MsmqMessageQueuePath @commonArgs) )
        }
        catch
        {
            Write-Error $_
            return
        }
        while( Test-MsmqMessageQueue @commonArgs )
        {
            Start-Sleep -Milliseconds 100
        }
    }
}

Set-Alias -Name 'Remove-MsmqMessageQueue' -Value 'Uninstall-MsmqMessageQueue'
