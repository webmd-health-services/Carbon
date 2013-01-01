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

function Convert-SecureStringToString
{
    <#
    .SYNOPSIS
    Converts a secure string into a plain text string.

    .DESCRIPTION
    Sometimes you just need to convert a secure string into a plain text string.  This function does it for you.  Yay!  Once you do, however, the cat is out of the bag and your password will be *all over memory* and, perhaps, the file system.

    .OUTPUTS
    System.String.

    .EXAMPLE
    Convert-SecureStringToString -SecureString $mySuperSecretPasswordIAmAboutToExposeToEveryone

    Returns the plain text/decrypted value of the secure string.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [Security.SecureString]
        # The secure string to convert.
        $SecureString
    )
    
    $stringPtr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    return [Runtime.InteropServices.Marshal]::PtrToStringAuto($stringPtr)
}
