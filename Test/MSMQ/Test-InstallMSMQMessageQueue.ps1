
# These tests should only run if MSMQ is not installed
if( Get-Service -Name MSMQ -ErrorAction SilentlyContinue )
{

    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    $publicQueueName = $null
    $privateQueueName = $null

    function Setup
    {
        Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
        $publicQueueName = 'CarbonTestQueue-Public' + [Guid]::NewGuid().ToString()
        $privateQueueName = 'CarbonTestQueue-Private' + [Guid]::NewGuid().ToString()
        Remove-TestQueues
    }

    function TearDown
    {
        Remove-TestQueues
        Remove-Module Carbon
    }
    
    function Remove-TestQueues
    {
        if( [Messaging.MessageQueue]::Exists(".\$publicQueueName") )
        {
            [Messaging.MessageQueue]::Delete(".\$publicQueueName")
        }
        
        if( [Messaging.MessageQueue]::Exists(".\Private`$\$privateQueueName") )
        {
            [Messaging.MessageQueue]::Delete(".\Private`$\$privateQueueName")
        }
    }

    function Test-ShouldInstallMessageQueue
    {
        Install-MSMQMessageQueue $publicQueueName
        $queue = Get-MSMQMessageQueue $publicQueueName
        Assert-False $queue.Transactional 
    }

    function Test-ShouldInstallPrivateQueue
    {
        Install-MSMQMessageQueue -Name $privateQueueName -Private
        $queue = Get-MSMQMessageQueue $privateQueueName -Private
        Assert-NotNull $queue
        Assert-False $queue.Transactional 
    }

    function Test-ShouldMakeQueueTransactional
    {
        Install-MSMQMessageQueue -Name $publicQueueName -Transactional
        $queue = Get-MSMQMessageQueue $publicQueueName
        Assert-NotNull $queue
        Assert-True $queue.Transactional
    }

    function Test-ShouldUpdateSettingsWhenInstallingExistingQueue
    {
        Install-MSMQMessageQueue -Name $publicQueueName
        $queue = Get-MSMQMessageQueue $publicqueueName
        Assert-False $queue.Transactional
        
        Install-MSMQMessageQueue -Name $publicQueueName -Transactional
        $queue = Get-MSMQMessageQueue $publicqueueName
        Assert-True $queue.Transactional
    }
    
    function Test-ShouldSupportWhatIf
    {
        Install-MSMQMessageQueue -Name $publicQueueName -WhatIf
        Assert-Null (Get-MSMQMessageQueue $publicQueueName)
    }
}
else
{
    Write-Warning "Tests for Install-MSMQMessageQueue not run because MSMQ is not installed."
}