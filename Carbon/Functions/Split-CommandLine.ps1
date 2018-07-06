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

function Split-CommandLine
{
    <#
    .SYNOPSIS
    Splits the specified command line command into it's executable and arguments parts

    .DESCRIPTION
    Unescapes the quotes where necessary and returns the executable and an array of arguments

    .EXAMPLE
    Split-CommandLine '"c:\path to executable\test.exe" "arg 1" arg2'

    Demonstrates how to split a command line string.  REturns 'c:\path to executable\test.exe' @('arg 1','arg2').
    #>

    [CmdletBinding()]
    param(
        [string]
        $Path
    )

    $quote = $false;
    $last = 0
    $ret = @()
    
    if(($Path -eq $null) -Or ($Path.Length -le 0))
    {
        $ret = @('')
    }
    else
    {
        $sb = New-Object -TypeName "System.Text.StringBuilder"

        for($i=0; $i -lt $Path.Length; $i++)
        {
            $char = $Path[$i]
        
            if($quote)
            {
                if($char -eq '"')
                {
                    if((($i + 1) -lt $Path.Length) -and ($Path[$i + 1] -eq '"'))
                    {
                        # it is an escaped double quote
                        $i++
                        $sb.Append('"') | Out-Null
                    }
                    else
                    {
                        $quote = $false
                    }
                }
                else
                {
                    $sb.Append($char) | Out-Null
                }
            }
            else
            {
                if($char -eq '"')
                {
                    $quote = $true
                }
                elseif($char -eq ' ')
                {
                    if($sb.Length -gt 0)
                    {
                        $ret += $sb.ToString()
                        $sb.Clear() | Out-Null
                    }
                }
                else
                {
                    $sb.Append($char) | Out-Null
                }
            }
        }

        if($sb.Length -gt 0)
        {
            $ret += $sb.ToString()
        }
    }

    #return exe path
    $ret[0]

    #return arguments
    if($ret.Count -gt 1)
    {
        $ret[1..($ret.Count - 1)]
    }
    else
    {
        $null
    }
}
