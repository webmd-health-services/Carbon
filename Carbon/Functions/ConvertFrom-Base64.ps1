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

function ConvertFrom-Base64
{
    <#
    .SYNOPSIS
    Converts a base-64 encoded string back into its original string.
    
    .DESCRIPTION
    For some reason. .NET makes encoding a string a two-step process. This function makes it a one-step process.
    
    You're actually allowed to pass in `$null` and an empty string.  If you do, you'll get `$null` and an empty string back.

    .LINK
    ConvertTo-Base64
    
    .EXAMPLE
    ConvertFrom-Base64 -Value 'RW5jb2RlIG1lLCBwbGVhc2Uh'
    
    Decodes `RW5jb2RlIG1lLCBwbGVhc2Uh` back into its original string.
    
    .EXAMPLE
    ConvertFrom-Base64 -Value 'RW5jb2RlIG1lLCBwbGVhc2Uh' -Encoding ([Text.Encoding]::ASCII)
    
    Shows how to specify a custom encoding in case your string isn't in Unicode text encoding.
    
    .EXAMPLE
    'RW5jb2RlIG1lIQ==' | ConvertTo-Base64
    
    Shows how you can pipeline input into `ConvertFrom-Base64`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [AllowNull()]
        [AllowEmptyString()]
        [string[]]
        # The base-64 string to convert.
        $Value,
        
        [Text.Encoding]
        # The encoding to use.  Default is Unicode.
        $Encoding = ([Text.Encoding]::Unicode)
    )
    
    begin
    {
        Set-StrictMode -Version 'Latest'

        Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    }

    process
    {
        $Value | ForEach-Object {
            if( $_ -eq $null )
            {
                return $null
            }
            
            $bytes = [Convert]::FromBase64String($_)
            $Encoding.GetString($bytes)
        }
    }
}
