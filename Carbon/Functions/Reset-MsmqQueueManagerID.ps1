
function Reset-CMsmqQueueManagerID
{
    <#
    .SYNOPSIS
    Resets the MSMQ Queue Manager ID.
    
    .DESCRIPTION
    Removes any existing MSMQ Queue Manager ID in the registry and restarts MSMQ so that it will generate a fresh QM ID.

    Each instance of MSMQ should have its own unique Queue Manager ID. If multiple machines have the same Queue Manager ID, destination queues think messages are actually coming from the same computer, and messages are lost/dropped.  If you clone new servers from a template or from old servers, you'll get duplicate Queue Manager IDs.  This function causes MSMQ to reset its Queue Manager ID.
    
    .EXAMPLE
    Reset-CMsmqQueueManagerId
    
    .LINK
    http://blogs.msdn.com/b/johnbreakwell/archive/2007/02/06/msmq-prefers-to-be-unique.aspx
    #>
    [CmdletBinding()]
    param(
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    Write-Verbose "Resetting MSMQ Queue Manager ID."
    Write-Verbose "Stopping MSMQ."
    Stop-Service MSMQ -Force
    
    $QMIdPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters\MachineCache"
    $QMIdName = "QMId"
   	$QMId = Get-CRegistryKeyValue -Path $QMIdPath -Name $QMIdName
   	Write-Verbose "Existing QMId: $QMId"
   	Remove-CRegistryKeyValue -Path $QMIdPath -Name $QMIdName
    
    $MSMQSysPrepPath = "HKLM:\SOFTWARE\Microsoft\MSMQ\Parameters"
    $MSMQSysPrepName = "SysPrep"
   	Remove-CRegistryKeyValue -Path $MSMQSysPrepPath -Name $MSMQSysPrepName
	Set-CRegistryKeyValue -Path $MSMQSysPrepPath -Name $MSMQSysPrepName -DWord 1
    
    Write-Verbose "Starting MSMQ"
    Start-Service MSMQ
    
	$QMId = Get-CRegistryKeyValue -Path $QMIdPath -Name $QMIdName
    Write-Verbose "New QMId: $QMId"
}

