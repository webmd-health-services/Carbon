
function Grant-CMsmqMessageQueuePermission
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
    Grant-CMsmqMessageQueuePermission -Name MovieQueue -Username REGAL\Employees -AccessRights FullControl

    Grants Regal Cinema employees full control over the MovieQueue.

    .EXAMPLE
    Grant-CMsmqMessageQueuePermission -Name MovieQueue -Private -Username REGAL\Critics -AccessRights WriteMessage    

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
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $queue = Get-CMsmqMessageQueue @queueArgs
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

Set-Alias -Name 'Grant-MsmqMessageQueuePermissions' -Value 'Grant-CMsmqMessageQueuePermission'

