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

function Get-PowerShellModuleInstallPath
{
    <#
    .SYNOPSIS
    Returns the path to the directory where you can install custom modules.

    .DESCRIPTION
    Custom modules should be installed under the `Program Files` directory. This function looks at the `PSModulePath` environment variable to find the install location under `Program Files`. If that path doesn't exist or isn't part of the `PSModulePath` environment variable, returns the module path under `$PSHOME`. If that path doesn't exist or isn't part of the `PSModulePath` environment variable, an error is written and nothing is returned.

    .EXAMPLE
    Get-PowerShellModuleInstallPath

    Demonstrates how to get the path where modules should be installed.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
    )

    Set-StrictMode -Version 'Latest'

    $modulePaths = $env:PSModulePath -split ';' 
    $installRoot = $modulePaths | Where-Object { $_ -like ('{0}\*' -f $env:ProgramFiles) }
    if( -not $installRoot -or -not (Test-Path -Path $installRoot -PathType Container) )
    {
        Write-Verbose ('Module path under ''{0}'' not found.' -f $env:ProgramFiles)
        $installRoot = $modulePaths | Where-Object { $_ -like ('{0}\*' -f $env:SystemRoot) }
        if( -not $installRoot -or -not (Test-Path -Path $installRoot -PathType Container) )
        {
            Write-Verbose ('Module path under ''{0}'' not found.' -f $env:SystemRoot)
            Write-Error ('Module path under ''{0}'' and ''{1}'' not found.' -f $env:ProgramFiles,$env:SystemRoot)
            return
        }
    }

    return $installRoot

}