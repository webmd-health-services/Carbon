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

function Grant-MsmqMessageQueuePermission
{
    <#
    .SYNOPSIS
    Grants a user permissions on an MSMQ message queue.

    .DESCRIPTION
    If you want users to be able to access your queue, you need to grant them access.  This function will do that.

    The rights you can assign are specified using values from the [MessageQueueAccessRights enumeration](http://msdn.microsoft.com/en-us/library/system.messaging.messagequeueaccessrights.aspx).  

    If your queue is private, make sure you set the `Private` switch.

    .LINK
    http://msdn.microsoft.com/en-us/library/system.messaging.messagequeueaccessrights.aspx

    .EXAMPLE
    Grant-MsmqMessageQueuePermission -Name MovieQueue -Username REGAL\Employees -AccessRights FullControl

    Grants Regal Cinema employees full control over the MovieQueue.

    .EXAMPLE
    Grant-MsmqMessageQueuePermission -Name MovieQueue -Private -Username REGAL\Critics -AccessRights WriteMessage    

    Grants all of Regal's approved movie critics permission to write to the private critic's `MovieQueue`.  Lucky!
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue name.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The user to grant permissions to.
        $Username,
        
        [Parameter(Mandatory=$true)]
        [Messaging.MessageQueueAccessRights[]]
        # The rights to grant the user.
        $AccessRights
    )

    Set-StrictMode -Version 'Latest'
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $queue = Get-MsmqMessageQueue @queueArgs
    if( -not $queue )
    {
        Write-Error "MSMQ queue '$Name' not found."
        return
    }
    
    if( $PSCmdlet.ShouldProcess( ('MSMQ queue ''{0}''' -f $Name), ("granting '{0}' rights to '{1}'" -f $AccessRights,$Username) ) )
    {
        $queue.SetPermissions( $Username, $AccessRights )
    }
}

Set-Alias -Name 'Grant-MsmqMessageQueuePermissions' -Value 'Grant-MsmqMessageQueuePermission'
