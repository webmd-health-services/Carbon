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

    function Test-ShouldFindPublicQueue
    {
        $queue = Get-MSMQMessageQueue -Name $publicQueueName
        Assert-NotNull $queue
        Assert-Equal $publicQueueName $queue.QueueName
    }

    function Test-ShouldFindPrivateQueue
    {
        $queue = Get-MSMQMessageQueue -Name $privateQueueName -Private
        Assert-NotNull $queue
        Assert-True $queue.QueueName.EndsWith( $privateQueueName  )
    }

    function Test-ShouldNotFindMissingPublicQueue
    {
        $queue = Get-MSMQMessageQueue -Name "IDoNotExist"
        Assert-Null $queue
    }
    function Test-ShouldNotFindMissingPrivateQueue
    {
        $queue = Get-MSMQMessageQueue -Name "IDoNotExist" -Private
        Assert-Null $queue
    }
}
else
{
    Write-Warning "Tests for Get-MSMQMessageQueue not run because MSMQ is not installed."
}
