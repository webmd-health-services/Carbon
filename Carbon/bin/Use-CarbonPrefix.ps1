<#
.SYNOPSIS
Updates files to use Carbon functions with the new `C` prefix.

.DESCRIPTION
The `Use-CarbonPrefix.ps1` script updates files to use Carbon functions with the new `C` prefix. You pass the path to the file(s) to update via the `Path` parameter. This script looks in each file for Carbon function names and updates them to include the new `C` prefix.

The `Path` parameter is passed as-is to the `Get-ChildItem` cmdlet, which does the work of actually finding the files to update. This script also has `Filter`, `Include`, `Exclude`, and `Recurse` parameters which are passed as-is to the `Get-ChildItem` cmdlet.

.EXAMPLE
.\Carbon\bin\Use-CarbonPrefix.ps1 -Path C:\Projects\MyProjects -Include '*.ps1' -Recurse

Demonstrates how to update all your PowerShell scripts to use the new Carbon command prefix in function names.
#>

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
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [Parameter(Mandatory)]
    [string[]]
    # The paths to update.
    $Path,
    
    [string]
    $Filter,

    [string[]]
    $Include,

    [string[]]
    $Exclude,

    [Switch]
    $Recurse
)

Set-StrictMode -Version 'Latest'

& (Join-Path -Path $PSScriptRoot -ChildPath '..\Import-Carbon.ps1' -Resolve) -Force

$commands = Get-Command -Module 'Carbon' | Where-Object { $_.CommandType -ne 'Alias' }
$commandNames = $commands | ForEach-Object { '{0}-{1}' -f $_.Verb,($_.Noun -replace '^C','') }
$regex = '\b({0})\b' -f ($commandNames -join '|')

$getChildItemParams = @{
                            Path = $Path;
                            Filter = $Filter;
                            Include = $Include;
                            Exclude = $Exclude;
                            Recurse = $Recurse;
                        }

foreach( $filePath in (Get-ChildItem @getChildItemParams -File) )
{
    $content = [IO.File]::ReadAllText($filePath.FullName)
    $changed = $false
    while( $content -match $regex )
    {
        $oldCommandName = $Matches[1]
        $newCommandName = $oldCommandName -replace '-','-C'
        
        [pscustomobject]@{
                            Path = $filePath;
                            OldName = $oldCommandName;
                            NewName = $newCommandName
                        }
        
        $content = $content -replace ('\b({0})\b' -f $oldCommandName),$newCommandName
        $changed = $true
    }

    if( $changed -and $PSCmdlet.ShouldProcess($filePath.FullName,'update') )
    {
        [IO.File]::WriteAllText($filePath.FullName,$content)
    }
}
