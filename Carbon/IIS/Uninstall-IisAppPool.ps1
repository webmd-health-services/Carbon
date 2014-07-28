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

function Uninstall-IisAppPool
{
    <#
    .SYNOPSIS
    Removes an IIS application pool.
    
    .DESCRIPTION
    If the app pool doesn't exist, nothing happens.
    
    .EXAMPLE
    Uninstall-IisAppPool -Name Batcave
    
    Removes/uninstalls the `Batcave` app pool.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The name of the app pool to remove.
        $Name
    )
    
    $appPool = Get-IisAppPool -Name $Name
    if( $appPool )
    {
        if( $pscmdlet.ShouldProcess( ('IIS app pool {0}' -f $Name), 'remove' ) )
        {
            $appPool.Delete()
            $appPool.CommitChanges()
        }
    }
}