

# These tests should only run if MSMQ is not installed
if( Get-Service -Name MSMQ -ErrorAction SilentlyContinue )
{

    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
    $publicQueueName = 'CarbonTestGetQueue-Public'
    $privateQueueName = 'CarbonTestGetQueue-Private'

    function Setup
    {
        Import-Module (Join-Path $TestDir ..\..\Carbon) -Force
        Install-MSMQMessageQueue $publicQueueName 
        Install-MSMQMessageQueue $privateQueueName -Private 
    }

    function TearDown
    {
        Remove-Module Carbon
        [Messaging.MessageQueue]::Delete(".\$publicQueueName")
        [Messaging.MessageQueue]::Delete(".\Private`$\$privateQueueName")
    }

    function Test-ShouldFindExistingPublicQueue
    {
        Assert-True (Test-MSMQMessageQueue $publicQueueName)
    }

    function Test-ShouldFindExistingPrivateQueue
    {
        Assert-True (Test-MSMQMessageQueue $privateQueueName -Private)
    }

    function Test-ShouldNotFindNonExistentPublicQueue
    {
        Assert-False (Test-MSMQMessageQueue "IDoNotExist")
    }
    function Test-ShouldNotFindNonExistentPrivateQueue
    {
        Assert-False (Test-MSMQMessageQueue "IDoNotExist" -Private)
    }
}
else
{
    Write-Warning "Tests for Test-MSMQMessageQueue not run because MSMQ is not installed."
}