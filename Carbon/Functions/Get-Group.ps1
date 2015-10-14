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

function Get-Group
{
    <#
    .SYNOPSIS
    Gets *local* groups.

    .DESCRIPTION
    `Get-Group` gets all *local* groups or a specific group by its name.

    The objects returned, `DirectoryServices.AccountManagement.GroupPrincipal`, use external resources, which means they don't clean up propertly when garbage collected, resulting in memory leaks. You should call `Dispose()` on the objects you receieve from this function when you're done using them so these external resources can be cleaned up correctly.

    `Get-Group` is new in Carbon 2.0.

    .OUTPUTS
    System.DirectoryServices.AccountManagement.GroupPrincipal.

    .LINK
    Get-User

    .EXAMPLE
    Get-Group

    Demonstrates how to get all local groups.

    .EXAMPLE
    Get-Group -Name RebelAlliance

    Demonstrates how to get a specific group.
    #>
    [CmdletBinding()]
    [OutputType([DirectoryServices.AccountManagement.GroupPrincipal])]
    param(
        [string]
        # The name of the group to return.
        $Name 
    )

    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState
    
    $ctx = New-Object 'DirectoryServices.AccountManagement.PrincipalContext' ([DirectoryServices.AccountManagement.ContextType]::Machine)
    if( $Name )
    {
        $group = [DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity( $ctx, $Name )
        if( -not $group )
        {
            try
            {
                Write-Error ('Local group ''{0}'' not found.' -f $Name) -ErrorAction:$ErrorActionPreference
                return
            }
            finally
            {
                $ctx.Dispose()
            }
        }
        return $group
    }
    else
    {
        $query = New-Object 'DirectoryServices.AccountManagement.GroupPrincipal' $ctx
        $searcher = New-Object 'DirectoryServices.AccountManagement.PrincipalSearcher' $query
        try
        {
            $searcher.FindAll() 
        }
        finally
        {
            $searcher.Dispose()
            $query.Dispose()
        }
    }
}

