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

$originalText = $null
$protectedText = $null

function Setup
{
    Import-Module (Join-Path $TestDir ..\..\Carbon) -Force

    $originalText = [Guid]::NewGuid().ToString()
    $protectedText = Protect-String -String $originalText -ForCurrentUser
}

function TearDown
{
    Remove-Module Carbon
}

function Test-ShouldUnprotectString
{
    $actualText = Unprotect-String -ProtectedString $protectedText
    Assert-Equal $originalText $actualText "String not decrypted."
}


function Test-ShouldUnprotectStringFromMachineScope
{
    $secret = Protect-String -String 'Hello World' -ForLocalComputer
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from local machine scope failed'
}

function Test-ShouldUnprotectStringFromUserScope
{
    $secret = Protect-String -String 'Hello World' -ForCurrentUser
    $machine = Unprotect-String -ProtectedString $secret
    Assert-Equal 'Hello World' $machine 'decrypting from user scope failed'
}


function Test-ShouldUnrotectStringsInPipeline
{
    $secrets = @('Foo','Fizz','Buzz','Bar') | Protect-String -ForCurrentUser | Unprotect-String 
    Assert-Equal 'Foo' $secrets[0] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Fizz' $secrets[1] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Buzz' $secrets[2] 'Didn''t decrypt first item in pipeline'
    Assert-Equal 'Bar' $secrets[3] 'Didn''t decrypt first item in pipeline'
}
