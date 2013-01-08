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

function Assert-WindowsFeatureFunctionsSupported
{
    <#
    .SYNOPSIS
    Asserts if Windows feature functions are supported.  If not, writes a warning and returns false.
    
    .DESCRIPTION 
    This is an internal function which is used to determine if the current operating system has tools installed which Carbon can use to manage Windows features.  On Windows 2008/Vista, the `servermanagercmd.exe` console program is used.  On Windows 2008 R2/7, the `ocsetup.exe` console program is used.
    
    **This function is not available on Windows 8/2012.**
    
    .EXAMPLE
    Assert-WindowsFeatureFunctionsSupported
    
    Writes an error and returns `false` if support for managing functions isn't found.
    #>
    [CmdletBinding()]
    param(
    )
    
    if( $windowsFeaturesNotSupported )
    {
        Write-Warning $supportNotFoundErrorMessage
        return $false
    }
    return $true
}
