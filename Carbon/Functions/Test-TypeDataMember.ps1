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

function Test-TypeDataMember
{
    <#
    .SYNOPSIS
    Tests if a type has an extended type member defined.

    .DESCRIPTION
    `Test-TypeDataMember` tests if a type has an extended type member defined. If the type isn't found, you'll get an error.

    Returns `$true` if the type is found and the member is defined. Otherwise, returns `$false`.

    This function is new in Carbon 2.0.

    .EXAMPLE
    Test-TypeDataMember -TypeName 'Microsoft.Web.Administration.Site' -MemberName 'PhysicalPath'

    Tests if the `Microsoft.Web.Administration.Site` type has a `PhysicalPath` extended type member defined.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        # The type name to check.
        $TypeName,

        [Parameter(Mandatory=$true)]
        [string]
        # The name of the member to check.
        $MemberName
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    $typeData = Get-TypeData -TypeName $TypeName
    if( -not $typeData )
    {
        # The type isn't defined or there is no extended type data on it.
        return $false
    }

    return $typeData.Members.ContainsKey( $MemberName )
}


