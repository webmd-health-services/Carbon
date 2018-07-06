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

function Join-ServiceArgumentList
{
    <#
    .SYNOPSIS
    Combines an executable path with arguments and escapes them where necessary, returning a syntactically valid command line command

    .DESCRIPTION
    Escapes spaces and quotes in the executable path and arguments specified.

    .EXAMPLE
    Join-ServiceArgumentList 'c:\path to executable\test.exe' 'arg 1','arg2'

    Demonstrates how to join an executable path and arguments together.  REturns '"c:\path to executable\test.exe" "arg 1" arg2'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $Path,
        
        [string[]]
        $ArgumentList
    )

    if($ArgumentList -eq $null)
    {
        $ArgumentList = @()
    }

    $binPathArg = Invoke-Command -ScriptBlock {
                        $Path
                        $ArgumentList 
                    } |
                    ForEach-Object { 
                        if((-not [string]::IsNullOrEmpty($_)))
                        {
                            if( $_.Contains(' ') -Or $_.Contains('"') )
                            {
                                #if the argument contains double quote chars, we need to escape them with double double quotes chars
                                return '"{0}"' -f $_.Replace('"', '""')
                            }
                            else
                            {
                                return $_
                            }
                        }
                    }
                    
    return ($binPathArg -join ' ')
}
