
function Install-CMsmqMessageQueue
{
    <#
    .SYNOPSIS
    Installs an MSMQ queue.

    .DESCRIPTION
    Creates a new queue with name `Name`.  If a queue with that name already exists, it is deleted, and a new queue is created. 

    If the queue needs to be private, pass the `Private` switch.  If it needs to be transactional, set the `Transactional` switch.
    
    .EXAMPLE
    Install-CMsmqMessageQueue -Name MovieQueue

    Installs a public, non-transactional `MovieQueue`.

    .EXAMPLE
    Install-CMsmqMessageQueue -Name CriticsQueue -Private -Transactional

    Installs a private, transactional `CriticsQueue` queue.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue.
        $Name,
        
        [Switch]
        # Makes a private queue.
        $Private,
        
        [Switch]
        # Makes a transactional queue.
        $Transactional
    )
    
    Set-StrictMode -Version 'Latest'
    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-CMsmqMessageQueuePath @queueArgs 
    
    $cmdletArgs = @{ }
    if( $PSBoundParameters.ContainsKey( 'WhatIf' ) )
    {
        $cmdletArgs.WhatIf = $true
    }
    
    $logMessage = "MSMQ message queue '$Name'."
    if( Test-CMsmqMessageQueue @queueArgs )
    {
        Write-Verbose "Re-creating $logMessage"
        Uninstall-CMsmqMessageQueue @queueArgs @cmdletArgs
    }
    else
    {
        Write-Verbose "Creating $logMessage"
    }
    
    $MaxWait = [TimeSpan]'0:00:10'
    $endAt = (Get-Date) + $MaxWait
    $created = $false
    if( $pscmdlet.ShouldProcess( $path, 'install MSMQ queue' ) )
    {
        # If you remove a queue, sometimes you can't immediately re-create it.  So, we keep trying until we can.
        do
        {
            try
            {
                # Capture the return object, otherwise it gets sent down the pipeline and causes an error
                $queue = [Messaging.MessageQueue]::Create( $path, $Transactional )
                $created = $true
                break
            }
            catch 
            { 
                if( $_.Exception.Message -like '*A workgroup installation computer does not support the operation.*' )
                {
                    Write-Error ("Can't create MSMSQ queues on this computer.  {0}" -f $_.Exception.Message)
                    return
                }
            }
            Start-Sleep -Milliseconds 100
        }
        while( -not $created -and (Get-Date) -lt $endAt )
        
        if( -not $created )
        {
            Write-Error ('Unable to create MSMQ queue {0}.' -f $path)
            return
        }
        
        $endAt = (Get-Date) + $MaxWait
        $exists = $false
        do
        {
            Start-Sleep -Milliseconds 100
            if( (Test-CMsmqMessageQueue @queueArgs) )
            {
                $exists = $true
                break
            }
        }
        while( (Get-Date) -lt $endAt -and -not $exists )
        
        if( -not $exists )
        {
            Write-Warning ('MSMSQ queue {0} created, but can''t be found.  Please double-check that the queue was created.' -f $path)
        }
    }
}

