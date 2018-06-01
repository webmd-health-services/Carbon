
function Register-WhiskeyEvent
{
    <#
    .SYNOPSIS
    Registers a command to call when specific events happen during a build.

    .DESCRIPTION
    The `Register-WhiskeyEvent` function registers a command to run when a specific event happens during a build. Supported events are:
    
    * `BeforeTask` which runs before each task
    * `AfterTask`, which runs after each task

    `BeforeTask` and `AfterTask` event handlers must have the following parameters:

        function Invoke-WhiskeyTaskEvent
        {
            param(
                [Parameter(Mandatory=$true)]
                [object]
                $TaskContext,

                [Parameter(Mandatory=$true)]
                [string]
                $TaskName,

                [Parameter(Mandatory=$true)]
                [hashtable]
                $TaskParameter
            )
        }

    To stop a build while handling an event, call the `Stop-WhiskeyTask` function.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the command to run during the event.
        $CommandName,

        [Parameter(Mandatory=$true)]
        [string]
        [ValidateSet('BeforeTask','AfterTask')]
        # When the command should be run; what events does it respond to?
        $Event,

        [string]
        # Only fire the event for a specific task.
        $TaskName
    )

    Set-StrictMode -Version 'Latest'

    $eventName = $Event
    if( $TaskName )
    {
        $eventType = $Event -replace 'Task$',''
        $eventName = '{0}{1}Task' -f $eventType,$TaskName
    }

    if( -not $events[$eventName] )
    {
        $events[$eventName] = New-Object -TypeName 'Collections.Generic.List[string]'
    }

    $events[$eventName].Add( $CommandName )
}