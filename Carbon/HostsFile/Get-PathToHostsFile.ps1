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

function Get-PathToHostsFile
{
    <#
    .SYNOPSIS
    Gets the path to this computer's hosts file.
    
    .DESCRIPTION
    This is a convenience method so you don't have to have the path to the hosts file hard-coded in your scripts.
    
    .EXAMPLE
    Get-PathToHostsFile
    
    Returns `C:\Windows\system32\drivers\etc\hosts`.  Uses the environment variable to find the root to the Windows directory.
    #>
    return Join-Path $env:windir system32\drivers\etc\hosts
}
