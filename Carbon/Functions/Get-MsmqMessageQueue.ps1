
function Get-CMsmqMessageQueue
{
    <#
    .SYNOPSIS
    Gets the MSMQ message queue by the given name

    .DESCRIPTION 
    Returns a [MessageQueue](http://msdn.microsoft.com/en-us/library/system.messaging.messagequeue.aspx) object for the Message Queue with name `Name`.  If one doesn't exist, returns `$null`.

    Because MSMQ handles private queues differently than public queues, you must explicitly tell `Get-CMsmqMessageQueue` the queue you want to get is private by using the `Private` switch.

    .OUTPUTS
    System.Messaging.MessageQueue.

    .EXAMPLE
    Get-CMsmqMessageQueue -Name LunchQueue

    Returns the [MessageQueue](http://msdn.microsoft.com/en-us/library/system.messaging.messagequeue.aspx) object for the queue named LunchQueue.  It's probably pretty full!

    .EXAMPLE
    Get-CMsmqMessageQueue -Name TeacherLunchQueue -Private

    Returns the [MessageQueue](http://msdn.microsoft.com/en-us/library/system.messaging.messagequeue.aspx) object for the teacher's private LunchQueue.  They must be medical professors.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue to get.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private
    )
   
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $privateArg = @{ Private = $Private }
    
    if( Test-CMsmqMessageQueue -Name $Name @privateArg )
    {
        $path = Get-CMsmqMessageQueuePath -Name $Name @privateArg 
        New-Object -TypeName Messaging.MessageQueue -ArgumentList ($path)
    }
    else
    {
        return $null
    }
}

