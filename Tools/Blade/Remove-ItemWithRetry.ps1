# Copyright 2012 - 2015 Aaron Jensen
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

function Remove-ItemWithRetry($item, [Switch]$Recurse)
{
    if( -not (Test-Path $item) )
    {
        return
    }
    
    $RecurseParam = if( $Recurse ) { '-Recurse' } else { '' }
    $numTries = 0
    do
    {
        if( -not (Test-Path $item) )
        {
            return $true
        }
        
        if( $Recurse )
        {
            Remove-Item $item -Recurse -Force -ErrorAction SilentlyContinue
        }
        else
        {
            Remove-Item $item -Force -ErrorAction SilentlyContinue
        }
        
        if( Test-Path $item )
        {
            Start-Sleep -Milliseconds 100
        }
        else
        {
            return $true
        }
        $numTries += 1
    }
    while( $numTries -lt 20 )
    return $false
}

