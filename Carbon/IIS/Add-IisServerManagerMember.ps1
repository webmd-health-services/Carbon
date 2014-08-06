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

filter Add-IisServerManagerMember
{
    <#
    .SYNOPSIS
    INTERNAL. Adds a `ServerManager` property and `CommitChanges()` method to an object.
    
    .DESCRIPTION
    This is an internal Carbon function for adding properties/methods to `Microsoft.Web.Administration` objects so that changes to them can be committed/saved.  It adds a `ServerManager` property, which is a reference to the `ServerManager` object which instantiated this object and a CommitChanges method, which calls down to the `ServerManager`'s `CommitChanges` method.
    
    .EXAMPLE
    $appPool | Add-IisServerManagerMember -ServerManager $manager -PassThru
    
    Adds a `ServerManager` property and `CommitChanges` method to `$appPool`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        # The object on which the server manager members will be added.
        $InputObject,
        
        [Parameter(Mandatory=$true)]
        [Microsoft.Web.Administration.ServerManager]
        # The server manager object to use as the basis for the new members.
        $ServerManager,
        
        [Switch]
        # If set, will return the input object.
        $PassThru
    )
    
    $InputObject | 
        Add-Member -MemberType NoteProperty -Name 'ServerManager' -Value $ServerManager -PassThru |
        Add-Member -MemberType ScriptMethod -Name 'CommitChanges' -Value { $this.ServerManager.CommitChanges() }
        
    if( $PassThru )
    {
        return $InputObject
    }
}
