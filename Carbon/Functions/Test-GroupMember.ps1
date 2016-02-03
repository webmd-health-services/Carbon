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

function Test-GroupMember
{
    <#
    .SYNOPSIS
    brief description of the function.

    .DESCRIPTION
    detailed description of the function.

    .PARAMETER  ParameterA
    description of the ParameterA parameter.

    .PARAMETER  ParameterB
    description of the ParameterB parameter.

    .EXAMPLE
    C:\> Get-Something -ParameterA 'One value' -ParameterB 32

    .EXAMPLE
    C:\> Get-Something 'One value' 32

    .INPUTS
    .String,System.Int32

    .OUTPUTS
    .String

    .NOTES
    information about the function go here.

    .LINK
    _functions_advanced

    .LINK
    _comment_based_help
    #>

[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string]
    $Name,

    [Parameter(Mandatory=$true)]
    [string] 
    $Member
)
    
    Set-StrictMode -Version 'Latest'

    Use-CallerPreference -Cmdlet $PSCmdlet -Session $ExecutionContext.SessionState

    # Get current group members (if group exists)
    if ((Test-Group -Name $Name))
    {
        $currMembers = ((Get-Group -Name $Name).Members)
        Write-Debug ('Current members of group {0}' -f $Name)
        ($currMembers | Select SamAccountName,ContextType,@{Name="Domain";Expression={($_.Context.Name)}} | Format-Table -AutoSize -Wrap | Out-String | Write-Debug)

        # Return value
        $userExists = $false
        # Loop through $currMembers looking to see if 
        foreach($cMember in $currMembers)
        {
            try
            {
                Write-Debug ('User Resolution - Start:    {0}' -f $Member)
                $secPrincipal = Resolve-Identity -Name $Member -ErrorAction Stop
            }
            catch
            {
                Write-Warning -Message ('User Resolution - Failed: {0}' -f $PSItem.Exception.Message)
                return $false
            }

            if ($secPrincipal)
            {
                if ($secPrincipal.Sid -eq $cMember.Sid)
                {
                    return $true                    
                }
            }
        }

        return $userExists
    }
    else
    {
        Write-Error ('Group ''{0}'' not found' -f $Name)
        return $false
    }
}