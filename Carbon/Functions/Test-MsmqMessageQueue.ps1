
function Test-CMsmqMessageQueue
{
    <#
    .SYNOPSIS
    Tests if an MSMQ message queue exists.

    .DESCRIPTION
    Returns `True` if a message queue with name `Name` exists.  `False` otherwise.

    .OUTPUTS
    System.Boolean.

    .EXAMPLE
    Test-CMsmqMessageQueue -Name 'MovieQueue'

    Returns `True` if public queue `MovieQueue` exists, `False` otherwise.

    .EXAMPLE
    Test-CMsmqMessageQueue -Name 'MovieCriticsQueue' -Private

    Returns `True` if private queue `MovieCriticsQueue` exists, `False` otherwise.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue name.
        $Name,
        
        [Switch]
        # If the queue is private, this switch must be set.
        $Private
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-CMsmqMessageQueuePath @queueArgs 
    return ( [Messaging.MessageQueue]::Exists( $path ) )
}

