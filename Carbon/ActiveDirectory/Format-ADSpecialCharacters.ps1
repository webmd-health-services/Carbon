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

function Format-ADSearchFilterValue
{
    <#
    .SYNOPSIS
    Escapes Active Directory special characters from a string.
    
    .DESCRIPTION
    There are special characters in Active Directory queries/searches.  This function escapes them so they aren't treated as AD commands/characters.
    
    .OUTPUTS
    System.String.  The input string with any Active Directory-sensitive characters escaped.
    
    .LINK
    http://msdn.microsoft.com/en-us/library/aa746475.aspx#special_characters

    .EXAMPLE
    Format-ADSearchFilterValue -String "I have AD special characters (I think)."

    Returns 

        I have AD special characters \28I think\29.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The string to escape.
        $String
    )
    
    $string = $string.Replace('\', '\5c')
    $string = $string.Replace('*', '\2a')
    $string = $string.Replace('(', '\28')
    $string = $string.Replace(')', '\29')
    $string = $string.Replace('/', '\2f')
    $string.Replace("`0", '\00')
}

Set-Alias -Name 'Format-ADSpecialCharacters' -Value 'Format-ADSearchFilterValue'
