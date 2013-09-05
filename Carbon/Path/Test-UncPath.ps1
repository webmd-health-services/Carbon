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

function Test-UncPath
{
    <#
    .SYNOPSIS
    Tests if a path is a UNC path.

    .DESCRIPTION
    Converts the path to a URI and returns the value of its `IsUnc` property.

    This function does not test if path exists.  Use `Test-Path` for that.

    .LINK
    Test-Path

    .LINK
    http://blogs.microsoft.co.il/blogs/ScriptFanatic//archive/2010/05/27/quicktip-how-to-validate-a-unc-path.aspx

    .EXAMPLE
    Test-UncPath -Path '\\computer\share'

    Returns `true` since `\\computer\share` is a UNC path.  Note that `Test-UncPath` does not have to exist.

    .EXAMPLE
    Test-UncPath -Path 'C:\Windows'

    Returns `false` since `C:\Windows` is not a UNC path.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The path to test/check.
        $Path
    )

    ([Uri]$Path).IsUnc

}
