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

function ConvertTo-InheritanceFlag
{
    <#
    .SYNOPSIS
    Converts a `Carbon.Security.ContainerInheritanceFlags` value to a `System.Security.AccessControl.InheritanceFlags` value.
    
    .DESCRIPTION
    The `Carbon.Security.ContainerInheritanceFlags` enumeration encapsulates oth `System.Security.AccessControl.InheritanceFlags` and `System.Security.AccessControl.PropagationFlags`.  Make sure you also call `ConvertTo-PropagationFlag` to get the propagation value.
    
    .OUTPUTS
    System.Security.AccessControl.InheritanceFlags.
    
    .LINK
    ConvertTo-PropagationFlag
    
    .LINK
    Grant-Permission
    
    .EXAMPLE
    ConvertTo-InheritanceFlag -ContainerInheritanceFlag ContainerAndSubContainersAndLeaves
    
    Returns `InheritanceFlags.ContainerInherit|InheritanceFlags.ObjectInherit`.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [Carbon.Security.ContainerInheritanceFlags]
        # The value to convert to an `InheritanceFlags` value.
		[Alias('ContainerInheritanceFlags')]
        $ContainerInheritanceFlag
    )

    $Flags = [Security.AccessControl.InheritanceFlags]
    $map = @{
        'Container' =                                  $Flags::None;
        'SubContainers' =                              $Flags::ContainerInherit;
        'Leaves' =                                     $Flags::ObjectInherit;
        'ChildContainers' =                            $Flags::ContainerInherit;
        'ChildLeaves' =                                $Flags::ObjectInherit;
        'ContainerAndSubContainers' =                  $Flags::ContainerInherit;
        'ContainerAndLeaves' =                         $Flags::ObjectInherit;
        'SubContainersAndLeaves' =                    ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ContainerAndChildContainers' =                $Flags::ContainerInherit;
        'ContainerAndChildLeaves' =                    $Flags::ObjectInherit;
        'ContainerAndChildContainersAndChildLeaves' = ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ContainerAndSubContainersAndLeaves' =        ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
        'ChildContainersAndChildLeaves' =             ($Flags::ContainerInherit -bor $Flags::ObjectInherit);
    }
    $key = $ContainerInheritanceFlag.ToString()
    if( $map.ContainsKey( $key) )
    {
        return $map[$key]
    }
    
    Write-Error ('Unknown Carbon.Security.ContainerInheritanceFlags enumeration value {0}.' -f $ContainerInheritanceFlag) 
}

Set-Alias -Name 'ConvertTo-InheritanceFlags' -Value 'ConvertTo-InheritanceFlag'
