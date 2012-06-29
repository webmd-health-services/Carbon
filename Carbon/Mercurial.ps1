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

function Set-HgrcDefaultPushUrl
{
    <#
    .SYNOPSIS
    OBSOLETE.  Use Set-IniEntry instead.

    .DESCRIPTION
    We've replaced this function with the more generic `Set-IniEntry`.  Call it like so:

        Set-IniEntry -Path (Join-Path $RepoPath .hg\hgrc -Resolve) -Section paths -Name 'default-push' -Value $DefaultPushUrl

    .EXAMPLE
    Set-IniEntry -Path (Join-Path $RepoPath .hg\hgrc -Resolve) -Section paths -Name 'default-push' -Value $DefaultPushUrl

    This example shows how to use `Set-IniEntry` instead of `Set-HgrcDefaultPushUrl`.
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to the repository whose default-push URL should be updated.
        $RepoPath,
        
        [Parameter(Mandatory=$true)]
        [string]
        # The value of the default-push URL.
        $DefaultPushUrl
    )
    
    $hgrcPath = Join-Path $RepoPath .hg\hgrc
    if( -not (Test-Path $hgrcPath -PathType Leaf) )
    {
        Write-Error "'$RepoPath' isn't a Mercurial repository; couldn't find '$hgrcPath'."
        return
    }
    
    Set-IniEntry -Path $hgrcPath -Section paths -Name 'default-push' -Value $DefaultPushUrl
}

