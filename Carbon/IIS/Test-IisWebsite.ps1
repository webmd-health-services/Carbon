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

function Test-IisWebsite
{
    <#
    .SYNOPSIS
    Tests if a website exists.

    .DESCRIPTION
    Returns `True` if a website with name `Name` exists.  `False` if it doesn't.

    .EXAMPLE
    Test-IisWebsite -Name 'Peanuts'

    Returns `True` if the `Peanuts` website exists.  `False` if it doesn't.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the website whose existence to check.
        $Name
    )
    
    $output = Invoke-AppCmd list site -ErrorAction SilentlyContinue
    foreach( $line in $output )
    {
        if( $line -like "SITE ""$Name""*" )
        {
            return $true
        }
    }
    return $false
}

Set-Alias -Name Test-IisWebsiteExists -Value Test-IisWebsite
