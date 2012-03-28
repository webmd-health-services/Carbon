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
