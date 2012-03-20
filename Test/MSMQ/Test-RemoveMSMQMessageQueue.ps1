
if( Get-Service -Name MSMQ -ErrorAction SilentlyContinue )
{

    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    $publicQueueName = $null
    $privateQueueName = $null

    function Setup
    {
        $publicQueueName = 'CarbonTestRemoveQueue-Public' + [Guid]::NewGuid().ToString()
        $privateQueueName = 'CarbonTestRemoveQueue-Private' + [Guid]::NewGuid().ToString()
        Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
        Install-MSMQMessageQueue $publicQueueName 
        Install-MSMQMessageQueue $privateQueueName -Private 
    }

    function TearDown
    {
        if( Test-MSMQMessageQueue -Name $publicQueueName )
        {
            [Messaging.MessageQueue]::Delete( (Get-MSMQMessageQueuePath -Name $publicQueueName) )
            Wait-ForQueueDeletion $publicQueueName
        }
        
        if( Test-MSMQMessageQueue -Name $privateQueueName -Private )
        {
            [Messaging.MessageQueue]::Delete( (Get-MSMQMessageQueuePath -Name $privateQueueName -Private) )
            Wait-ForQueueDeletion $privateQueueName -Private 
        }
        Remove-Module Carbon
    }
    
    function Test-ShouldRemovePublicMessageQueue
    {
        Remove-MSMQMessageQueue $publicQueueName
        Assert-False (Test-MSMQMessageQueue $publicQueueName)
    }
    
    function Test-ShouldRemovePrivateMessageQueue
    {
        Remove-MSMQMessageQueue $privateQueueName -Private
        Assert-False (Test-MSMQMessageQueue $privateQueueName -Private)
    }
    
    function Test-ShouldSupportWhatIf
    {
        Remove-MSMQMessageQueue $publicQueueName -WhatIf
        Assert-True (Test-MSMQMessageQueue $publicQueueName)
    }
    
    function Wait-ForQueueDeletion($Name, [Switch]$Private)
    {
        $queueArgs = @{ Name = $Name ; Private = $Private }
        while( Test-MSMQMessageQueue @queueArgs )
        {
            Start-Sleep -Milliseconds 1000
        }
    }
    

}
else
{
    Write-Warning "Tests for Remove-MSMQMessageQueue not run because MSMQ is not installed."
}