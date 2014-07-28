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

function Install-MsmqMessageQueue
{
    <#
    .SYNOPSIS
    Installs an MSMQ queue.

    .DESCRIPTION
    Creates a new queue with name `Name`.  If a queue with that name already exists, it is deleted, and a new queue is created. 

    If the queue needs to be private, pass the `Private` switch.  If it needs to be transactional, set the `Transactional` switch.
    
    .EXAMPLE
    Install-MsmqMessageQueue -Name MovieQueue

    Installs a public, non-transactional `MovieQueue`.

    .EXAMPLE
    Install-MsmqMessageQueue -Name CriticsQueue -Private -Transactional

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
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-MsmqMessageQueuePath @queueArgs 
    
    $cmdletArgs = @{ }
    if( $PSBoundParameters.ContainsKey( 'WhatIf' ) )
    {
        $cmdletArgs.WhatIf = $true
    }
    
    $logMessage = "MSMQ message queue '$Name'."
    if( Test-MsmqMessageQueue @queueArgs )
    {
        Write-Verbose "Re-creating $logMessage"
        Uninstall-MsmqMessageQueue @queueArgs @cmdletArgs
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
            if( (Test-MsmqMessageQueue @queueArgs) )
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
