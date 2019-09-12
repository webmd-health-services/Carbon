
function Uninstall-CMsmqMessageQueue
{
    <#
    .SYNOPSIS
    Removes an MSMQ queue.

    .DESCRIPTION
    Removes/deletes an existing MSMQ queue by name.  If a queue with that name doesn't exist, nothing happens.

    .EXAMPLE
    Uninstall-CMsmqMessageQueue -Name MovieQueue

    Removes the public `MovieQueue` queue.

    .EXAMPLE
    Uninstall-CMsmqMessageQueue -Name MovieCriticsQueue -Private

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
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $commonArgs = @{ 'Name' = $Name ; 'Private' = $Private }
    
    if( -not (Test-CMsmqMessageQueue @commonArgs) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( "MSMQ Message Queue $Name", "remove" ) )
    {
        try
        {
            [Messaging.MessageQueue]::Delete( (Get-CMsmqMessageQueuePath @commonArgs) )
        }
        catch
        {
            Write-Error $_
            return
        }
        while( Test-CMsmqMessageQueue @commonArgs )
        {
            Start-Sleep -Milliseconds 100
        }
    }
}

Set-Alias -Name 'Remove-MsmqMessageQueue' -Value 'Uninstall-CMsmqMessageQueue'

