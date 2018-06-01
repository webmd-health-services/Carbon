
function Unregister-WhiskeyEvent
{
    <#
    .SYNOPSIS
    Unregisters a command to call when specific events happen during a build.

    .DESCRIPTION
    The `Unregister-WhiskeyEvent` function unregisters a command to run when a specific event happens during a build. This function is paired with `Register-WhiskeyEvent'.
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
        # The specific task whose events to unregister.
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
        return
    }

    if( -not $Events[$eventName].Contains( $CommandName ) )
    {
        return
    }

    $events[$eventName].Remove( $CommandName )
}