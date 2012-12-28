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

function Get-IisVersion
{
    <#
    .SYNOPSIS
    Gets the version of IIS.
    
    .DESCRIPTION
    Reads the version of IIS from the registry, and returns it as a `Major.Minor` formatted string.
    
    .EXAMPLE
    Get-IisVersion
    
    Returns `7.0` on Windows 2008, and `7.5` on Windows 7 and Windows 2008 R2.
    #>
    [CmdletBinding()]
    param(
    )
    $props = Get-ItemProperty hklm:\Software\Microsoft\InetStp
    return $props.MajorVersion.ToString() + "." + $props.MinorVersion.ToString()
}
