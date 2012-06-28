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

Add-Type -AssemblyName System.ServiceProcess
Add-Type -AssemblyName System.Messaging

function Get-MsmqMessageQueue
{
    <#
    .SYNOPSIS
    Gets the MSMQ message queue by the given name

    .DESCRIPTION 
    Returns a [MessageQueue](http://msdn.microsoft.com/en-us/library/system.messaging.messagequeue.aspx) object for the Message Queue with name `Name`.  If one doesn't exist, returns `$null`.

    Because MSMQ handles private queues differently than public queues, you must explicitly tell `Get-MsmqMessageQueue` the queue you want to get is private by using the `Private` switch.

    .OUTPUTS
    System.Messaging.MessageQueue.

    .EXAMPLE
    Get-MsmqMessageQueue -Name LunchQueue

    Returns the [MessageQueue](http://msdn.microsoft.com/en-us/library/system.messaging.messagequeue.aspx) object for the queue named LunchQueue.  It's probably pretty full!

    .EXAMPLE
    Get-MsmqMessageQueue -Name TeacherLunchQueue -Private

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
   
    $privateArg = @{ Private = $Private }
    
    if( Test-MSMQMessageQueue -Name $Name @privateArg )
    {
        $path = Get-MSMQMessageQueuePath -Name $Name @privateArg 
        New-Object -TypeName Messaging.MessageQueue -ArgumentList ($path)
    }
    else
    {
        return $null
    }
}

function Get-MsmqMessageQueuePath
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
    Get-MsmqMessageQueuePath -Name MovieQueue

    Returns the path to the `MovieQueue` queue.

    .EXAMPLE
    Get-MsmqMessageQueuePath -Name MovieQueue -Private

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
    
    $path = ".\$Name"
    if( $Private )
    {
        $path = ".\private`$\$Name"
    }
    return $path
}

function Grant-MsmqMessageQueuePermissions
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
    Grant-MsmqMessageQueuePermissions -Name MovieQueue -Username REGAL\Employees -AccessRights FullControl

    Grants Regal Cinema employees full control over the MovieQueue.

    .EXAMPLE
    Grant-MsmqMessageQueuePermissions -Name MovieQueue -Private -Username REGAL\Critics -AccessRights WriteMessage    

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
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $queue = Get-MSMQMessageQueue @queueArgs
    if( -not $queue )
    {
        throw "Queue '$Name' doesn't exist."
    }
    
    if( $pscmdlet.ShouldProcess( $Name, "grant '$AccessRights' to '$User'" ) )
    {
        Write-Host "Granting user '$Username' '$AccessRights' permissions to MSMQ message queue '$Name'."
        $queue.SetPermissions( $Username, $AccessRights )
    }
}

function Install-Msmq
{
    <#
    .SYNOPSIS
    Installs Microsoft's Message Queueing system/feature.

    .DESCRIPTION
    Microsoft's MSMQ is *not* installed by default.  It has to be turned on manually.   This function will enable the MSMQ feature.  There are two sub-features: Active Directory integration and HTTP support.  These can also be enabled by setting the `ActiveDirectoryIntegration` and `HttpSupport` switches, respectively.  If MSMQ will be working with queues on other machines, you'll need to enable DTC (the Distributed Transaction Coordinator) by passing the `DTC` switch.

     This function uses Microsoft's feature management command line utilities: `ocsetup.exe` or `servermanagercmd.exe`. **A word of warning**, however.  In our experience, **these tools do not seem to work as advertised**.  They are very slow, and, at least with MSMQ, we have intermittent errors installing it on our developer's Windows 7 computers.  We strongly recommend you install MSMQ manually on a base VM or computer image so that it's a standard part of your installation.  If that isn't possible in your environment, good luck!  let us know how it goes.

    If you know better ways of installing MSMQ or other Windows features, or can help us figure out why Microsoft's command line installation tools don't work consistently, we would appreciate it.

    .EXAMPLE
    Install-Msmq

    Installs MSMQ on this meachine.  In our experience, this may or may not work.  You'll want to check that the MSMQ service exists and is running after this.  Please help us make this better!

    .EXAMPLE
    Install-Msmq -HttpSupport -ActiveDirectoryIntegration -Dtc

    Installs MSMQ with the HTTP support and Active Directory sub-features.  Enables and starts the Distributed Transaction Coordinator.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Switch]
        # Enable HTTP Support
        $HttpSupport,
        
        [Switch]
        # Enable Active Directory Integrations
        $ActiveDirectoryIntegration,
        
        [Switch]
        # Will MSMQ be participating in external, distributed transactions? I.e. will it be sending messages to queues on other machines?
        $Dtc
    )
    
    $optionalArgs = @{ }
    if( $HttpSupport )
    {
        $optionalArgs.HttpSupport = $true
    }
    
    if( $ActiveDirectoryIntegration )
    {
        $optionalArgs.ActiveDirectoryIntegration = $true
    }
    
    Install-WindowsFeatureMsmq @optionalArgs
    
    if( $Dtc )
    {
        Set-Service -Name MSDTC -StartupType Automatic
        Start-Service -Name MSDTC
        $svc = Get-Service -Name MSDTC
        $svc.WaitForStatus( [ServiceProcess.ServiceControllerStatus]::Running )
    }
}

function Install-MSMQMessageQueue
{
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the queue.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private,
        
        [Switch]
        # Is the queue transactional?
        $Transactional
    )
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-MSMQMessageQueuePath @queueArgs 
    
    $logMessage = "MSMQ message queue '$Name'."
    if( Test-MSMQMessageQueue @queueArgs )
    {
        Write-Host "Re-creating $logMessage"
        Remove-MSMQMessageQueue @queueArgs
    }
    else
    {
        Write-Host "Creating $logMessage"
    }
    
    # If you remove a queue, sometimes you can't immediately re-create it.  So, we keep trying until we can.
    do
    {
        try
        {
            # Capture the return object, otherwise it gets sent down the pipeline and causes an error
            $queue = [Messaging.MessageQueue]::Create( $path, $Transactional )
            break
        }
        catch { }
        Start-Sleep -Milliseconds 100
    }
    while( $true )
    
    while( -not (Test-MSMQMessageQueue @queueArgs) )
    {
        Start-Sleep -Milliseconds 100
    }
}

function Remove-MSMQMessageQueue
{
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
    
    $commonArgs = @{ 'Name' = $Name ; 'Private' = $Private }
    
    if( -not (Test-MSMQMessageQueue @commonArgs) )
    {
        return
    }
    
    if( $pscmdlet.ShouldProcess( "MSMQ Message Queue $Name", "remove" ) )
    {
        try
        {
            [Messaging.MessageQueue]::Delete( (Get-MSMQMessageQueuePath @commonArgs) )
        }
        catch
        {
            Write-Error $_
            return
        }
        while( Test-MSMQMessageQueue @commonArgs )
        {
            Start-Sleep -Milliseconds 100
        }
    }
}

function Test-MSMQMessageQueue
{
    <#
    .SYNOPSIS
    Tests if an MSMQ message queue exists.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The queue name.
        $Name,
        
        [Switch]
        # Is the queue private?
        $Private
    )
    
    $queueArgs = @{ Name = $Name ; Private = $Private }
    $path = Get-MSMQMessageQueuePath @queueArgs 
    return ( [Messaging.MessageQueue]::Exists( $path ) )
}

