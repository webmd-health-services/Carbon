
function Get-CMsmqMessageQueuePath
{
    <#
    .SYNOPSIS
    Gets the path to an MSMQ message queue.

    .DESCRIPTION
    The MSMQ APIs expect paths when identifying a queue.  This function converts a queue name into its path so that logic isn't spread across all your scripts.  

    Private queue paths are constructed differently.  If you need to get the path to a private MSMQ, use the `Private` switch.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Get-CMsmqMessageQueuePath -Name MovieQueue

    Returns the path to the `MovieQueue` queue.

    .EXAMPLE
    Get-CMsmqMessageQueuePath -Name MovieQueue -Private

    Returns the path to the private `MovieQueue`.  Must be for the critics.  Early access for the win!
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue's name.  
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private
    )
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $path = ".\$Name"
    if( $Private )
    {
        $path = ".\private`$\$Name"
    }
    return $path
}

